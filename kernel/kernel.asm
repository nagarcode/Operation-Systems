
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
    80000068:	d1c78793          	addi	a5,a5,-740 # 80005d80 <timervec>
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
    80000122:	420080e7          	jalr	1056(ra) # 8000253e <either_copyin>
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
    800001c6:	eea080e7          	jalr	-278(ra) # 800020ac <sleep>
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
    80000202:	2ea080e7          	jalr	746(ra) # 800024e8 <either_copyout>
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
    800002e2:	2b6080e7          	jalr	694(ra) # 80002594 <procdump>
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
    80000436:	e06080e7          	jalr	-506(ra) # 80002238 <wakeup>
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
    80000882:	9ba080e7          	jalr	-1606(ra) # 80002238 <wakeup>
    
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
    8000090e:	7a2080e7          	jalr	1954(ra) # 800020ac <sleep>
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
    80000eb6:	824080e7          	jalr	-2012(ra) # 800026d6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	f06080e7          	jalr	-250(ra) # 80005dc0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	038080e7          	jalr	56(ra) # 80001efa <scheduler>
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
    80000f2e:	784080e7          	jalr	1924(ra) # 800026ae <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00001097          	auipc	ra,0x1
    80000f36:	7a4080e7          	jalr	1956(ra) # 800026d6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	e70080e7          	jalr	-400(ra) # 80005daa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	e7e080e7          	jalr	-386(ra) # 80005dc0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	04c080e7          	jalr	76(ra) # 80002f96 <binit>
    iinit();         // inode cache
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	6de080e7          	jalr	1758(ra) # 80003630 <iinit>
    fileinit();      // file table
    80000f5a:	00003097          	auipc	ra,0x3
    80000f5e:	68c080e7          	jalr	1676(ra) # 800045e6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f80080e7          	jalr	-128(ra) # 80005ee2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d52080e7          	jalr	-686(ra) # 80001cbc <userinit>
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
    800019f0:	d02080e7          	jalr	-766(ra) # 800026ee <usertrapret>
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
    80001a0a:	baa080e7          	jalr	-1110(ra) # 800035b0 <fsinit>
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
    80001b9c:	7139                	addi	sp,sp,-64
    80001b9e:	fc06                	sd	ra,56(sp)
    80001ba0:	f822                	sd	s0,48(sp)
    80001ba2:	f426                	sd	s1,40(sp)
    80001ba4:	f04a                	sd	s2,32(sp)
    80001ba6:	0080                	addi	s0,sp,64
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
    80001bda:	a055                	j	80001c7e <allocproc+0xe2>
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
    80001bf6:	c959                	beqz	a0,80001c8c <allocproc+0xf0>
  p->pagetable = proc_pagetable(p);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e5c080e7          	jalr	-420(ra) # 80001a56 <proc_pagetable>
    80001c02:	892a                	mv	s2,a0
    80001c04:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c06:	cd59                	beqz	a0,80001ca4 <allocproc+0x108>
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
    performance[i]=0; 
    80001c30:	fc042423          	sw	zero,-56(s0)
    80001c34:	fc042623          	sw	zero,-52(s0)
    80001c38:	fc042823          	sw	zero,-48(s0)
    80001c3c:	fc042a23          	sw	zero,-44(s0)
    80001c40:	fc042c23          	sw	zero,-40(s0)
    80001c44:	fc042e23          	sw	zero,-36(s0)
  p->performance = (struct perf*)performance;
    80001c48:	fc840793          	addi	a5,s0,-56
    80001c4c:	16f4b423          	sd	a5,360(s1)
  acquire(&tickslock);
    80001c50:	00015517          	auipc	a0,0x15
    80001c54:	68050513          	addi	a0,a0,1664 # 800172d0 <tickslock>
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	f6a080e7          	jalr	-150(ra) # 80000bc2 <acquire>
  p->performance->ctime = ticks;
    80001c60:	1684b783          	ld	a5,360(s1)
    80001c64:	00007717          	auipc	a4,0x7
    80001c68:	3cc72703          	lw	a4,972(a4) # 80009030 <ticks>
    80001c6c:	c398                	sw	a4,0(a5)
  release(&tickslock);
    80001c6e:	00015517          	auipc	a0,0x15
    80001c72:	66250513          	addi	a0,a0,1634 # 800172d0 <tickslock>
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	000080e7          	jalr	ra # 80000c76 <release>
}
    80001c7e:	8526                	mv	a0,s1
    80001c80:	70e2                	ld	ra,56(sp)
    80001c82:	7442                	ld	s0,48(sp)
    80001c84:	74a2                	ld	s1,40(sp)
    80001c86:	7902                	ld	s2,32(sp)
    80001c88:	6121                	addi	sp,sp,64
    80001c8a:	8082                	ret
    freeproc(p);
    80001c8c:	8526                	mv	a0,s1
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	eb6080e7          	jalr	-330(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	fde080e7          	jalr	-34(ra) # 80000c76 <release>
    return 0;
    80001ca0:	84ca                	mv	s1,s2
    80001ca2:	bff1                	j	80001c7e <allocproc+0xe2>
    freeproc(p);
    80001ca4:	8526                	mv	a0,s1
    80001ca6:	00000097          	auipc	ra,0x0
    80001caa:	e9e080e7          	jalr	-354(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001cae:	8526                	mv	a0,s1
    80001cb0:	fffff097          	auipc	ra,0xfffff
    80001cb4:	fc6080e7          	jalr	-58(ra) # 80000c76 <release>
    return 0;
    80001cb8:	84ca                	mv	s1,s2
    80001cba:	b7d1                	j	80001c7e <allocproc+0xe2>

0000000080001cbc <userinit>:
{
    80001cbc:	1101                	addi	sp,sp,-32
    80001cbe:	ec06                	sd	ra,24(sp)
    80001cc0:	e822                	sd	s0,16(sp)
    80001cc2:	e426                	sd	s1,8(sp)
    80001cc4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	ed6080e7          	jalr	-298(ra) # 80001b9c <allocproc>
    80001cce:	84aa                	mv	s1,a0
  initproc = p;
    80001cd0:	00007797          	auipc	a5,0x7
    80001cd4:	34a7bc23          	sd	a0,856(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cd8:	03400613          	li	a2,52
    80001cdc:	00007597          	auipc	a1,0x7
    80001ce0:	d7458593          	addi	a1,a1,-652 # 80008a50 <initcode>
    80001ce4:	6928                	ld	a0,80(a0)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	64e080e7          	jalr	1614(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001cee:	6785                	lui	a5,0x1
    80001cf0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cf2:	6cb8                	ld	a4,88(s1)
    80001cf4:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cf8:	6cb8                	ld	a4,88(s1)
    80001cfa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfc:	4641                	li	a2,16
    80001cfe:	00006597          	auipc	a1,0x6
    80001d02:	4ea58593          	addi	a1,a1,1258 # 800081e8 <digits+0x1a8>
    80001d06:	15848513          	addi	a0,s1,344
    80001d0a:	fffff097          	auipc	ra,0xfffff
    80001d0e:	106080e7          	jalr	262(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d12:	00006517          	auipc	a0,0x6
    80001d16:	4e650513          	addi	a0,a0,1254 # 800081f8 <digits+0x1b8>
    80001d1a:	00002097          	auipc	ra,0x2
    80001d1e:	2c4080e7          	jalr	708(ra) # 80003fde <namei>
    80001d22:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d26:	478d                	li	a5,3
    80001d28:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	f4a080e7          	jalr	-182(ra) # 80000c76 <release>
}
    80001d34:	60e2                	ld	ra,24(sp)
    80001d36:	6442                	ld	s0,16(sp)
    80001d38:	64a2                	ld	s1,8(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <growproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	e04a                	sd	s2,0(sp)
    80001d48:	1000                	addi	s0,sp,32
    80001d4a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d4c:	00000097          	auipc	ra,0x0
    80001d50:	c46080e7          	jalr	-954(ra) # 80001992 <myproc>
    80001d54:	892a                	mv	s2,a0
  sz = p->sz;
    80001d56:	652c                	ld	a1,72(a0)
    80001d58:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d5c:	00904f63          	bgtz	s1,80001d7a <growproc+0x3c>
  else if (n < 0)
    80001d60:	0204cc63          	bltz	s1,80001d98 <growproc+0x5a>
  p->sz = sz;
    80001d64:	1602                	slli	a2,a2,0x20
    80001d66:	9201                	srli	a2,a2,0x20
    80001d68:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d6c:	4501                	li	a0,0
}
    80001d6e:	60e2                	ld	ra,24(sp)
    80001d70:	6442                	ld	s0,16(sp)
    80001d72:	64a2                	ld	s1,8(sp)
    80001d74:	6902                	ld	s2,0(sp)
    80001d76:	6105                	addi	sp,sp,32
    80001d78:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d7a:	9e25                	addw	a2,a2,s1
    80001d7c:	1602                	slli	a2,a2,0x20
    80001d7e:	9201                	srli	a2,a2,0x20
    80001d80:	1582                	slli	a1,a1,0x20
    80001d82:	9181                	srli	a1,a1,0x20
    80001d84:	6928                	ld	a0,80(a0)
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	668080e7          	jalr	1640(ra) # 800013ee <uvmalloc>
    80001d8e:	0005061b          	sext.w	a2,a0
    80001d92:	fa69                	bnez	a2,80001d64 <growproc+0x26>
      return -1;
    80001d94:	557d                	li	a0,-1
    80001d96:	bfe1                	j	80001d6e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d98:	9e25                	addw	a2,a2,s1
    80001d9a:	1602                	slli	a2,a2,0x20
    80001d9c:	9201                	srli	a2,a2,0x20
    80001d9e:	1582                	slli	a1,a1,0x20
    80001da0:	9181                	srli	a1,a1,0x20
    80001da2:	6928                	ld	a0,80(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	602080e7          	jalr	1538(ra) # 800013a6 <uvmdealloc>
    80001dac:	0005061b          	sext.w	a2,a0
    80001db0:	bf55                	j	80001d64 <growproc+0x26>

0000000080001db2 <fork>:
{
    80001db2:	7139                	addi	sp,sp,-64
    80001db4:	fc06                	sd	ra,56(sp)
    80001db6:	f822                	sd	s0,48(sp)
    80001db8:	f426                	sd	s1,40(sp)
    80001dba:	f04a                	sd	s2,32(sp)
    80001dbc:	ec4e                	sd	s3,24(sp)
    80001dbe:	e852                	sd	s4,16(sp)
    80001dc0:	e456                	sd	s5,8(sp)
    80001dc2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc4:	00000097          	auipc	ra,0x0
    80001dc8:	bce080e7          	jalr	-1074(ra) # 80001992 <myproc>
    80001dcc:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dce:	00000097          	auipc	ra,0x0
    80001dd2:	dce080e7          	jalr	-562(ra) # 80001b9c <allocproc>
    80001dd6:	12050063          	beqz	a0,80001ef6 <fork+0x144>
    80001dda:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001ddc:	048ab603          	ld	a2,72(s5)
    80001de0:	692c                	ld	a1,80(a0)
    80001de2:	050ab503          	ld	a0,80(s5)
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	754080e7          	jalr	1876(ra) # 8000153a <uvmcopy>
    80001dee:	04054863          	bltz	a0,80001e3e <fork+0x8c>
  np->sz = p->sz;
    80001df2:	048ab783          	ld	a5,72(s5)
    80001df6:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dfa:	058ab683          	ld	a3,88(s5)
    80001dfe:	87b6                	mv	a5,a3
    80001e00:	0589b703          	ld	a4,88(s3)
    80001e04:	12068693          	addi	a3,a3,288
    80001e08:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0c:	6788                	ld	a0,8(a5)
    80001e0e:	6b8c                	ld	a1,16(a5)
    80001e10:	6f90                	ld	a2,24(a5)
    80001e12:	01073023          	sd	a6,0(a4)
    80001e16:	e708                	sd	a0,8(a4)
    80001e18:	eb0c                	sd	a1,16(a4)
    80001e1a:	ef10                	sd	a2,24(a4)
    80001e1c:	02078793          	addi	a5,a5,32
    80001e20:	02070713          	addi	a4,a4,32
    80001e24:	fed792e3          	bne	a5,a3,80001e08 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e28:	0589b783          	ld	a5,88(s3)
    80001e2c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e30:	0d0a8493          	addi	s1,s5,208
    80001e34:	0d098913          	addi	s2,s3,208
    80001e38:	150a8a13          	addi	s4,s5,336
    80001e3c:	a00d                	j	80001e5e <fork+0xac>
    freeproc(np);
    80001e3e:	854e                	mv	a0,s3
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	d04080e7          	jalr	-764(ra) # 80001b44 <freeproc>
    release(&np->lock);
    80001e48:	854e                	mv	a0,s3
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	e2c080e7          	jalr	-468(ra) # 80000c76 <release>
    return -1;
    80001e52:	597d                	li	s2,-1
    80001e54:	a079                	j	80001ee2 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e56:	04a1                	addi	s1,s1,8
    80001e58:	0921                	addi	s2,s2,8
    80001e5a:	01448b63          	beq	s1,s4,80001e70 <fork+0xbe>
    if (p->ofile[i])
    80001e5e:	6088                	ld	a0,0(s1)
    80001e60:	d97d                	beqz	a0,80001e56 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e62:	00003097          	auipc	ra,0x3
    80001e66:	816080e7          	jalr	-2026(ra) # 80004678 <filedup>
    80001e6a:	00a93023          	sd	a0,0(s2)
    80001e6e:	b7e5                	j	80001e56 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e70:	150ab503          	ld	a0,336(s5)
    80001e74:	00002097          	auipc	ra,0x2
    80001e78:	976080e7          	jalr	-1674(ra) # 800037ea <idup>
    80001e7c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e80:	4641                	li	a2,16
    80001e82:	158a8593          	addi	a1,s5,344
    80001e86:	15898513          	addi	a0,s3,344
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	f86080e7          	jalr	-122(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e92:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e96:	854e                	mv	a0,s3
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	dde080e7          	jalr	-546(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001ea0:	0000f497          	auipc	s1,0xf
    80001ea4:	41848493          	addi	s1,s1,1048 # 800112b8 <wait_lock>
    80001ea8:	8526                	mv	a0,s1
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	d18080e7          	jalr	-744(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001eb2:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	dbe080e7          	jalr	-578(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001ec0:	854e                	mv	a0,s3
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	d00080e7          	jalr	-768(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eca:	478d                	li	a5,3
    80001ecc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ed0:	854e                	mv	a0,s3
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	da4080e7          	jalr	-604(ra) # 80000c76 <release>
  np->traceMask = p->traceMask;
    80001eda:	034aa783          	lw	a5,52(s5)
    80001ede:	02f9aa23          	sw	a5,52(s3)
}
    80001ee2:	854a                	mv	a0,s2
    80001ee4:	70e2                	ld	ra,56(sp)
    80001ee6:	7442                	ld	s0,48(sp)
    80001ee8:	74a2                	ld	s1,40(sp)
    80001eea:	7902                	ld	s2,32(sp)
    80001eec:	69e2                	ld	s3,24(sp)
    80001eee:	6a42                	ld	s4,16(sp)
    80001ef0:	6aa2                	ld	s5,8(sp)
    80001ef2:	6121                	addi	sp,sp,64
    80001ef4:	8082                	ret
    return -1;
    80001ef6:	597d                	li	s2,-1
    80001ef8:	b7ed                	j	80001ee2 <fork+0x130>

0000000080001efa <scheduler>:
{
    80001efa:	7139                	addi	sp,sp,-64
    80001efc:	fc06                	sd	ra,56(sp)
    80001efe:	f822                	sd	s0,48(sp)
    80001f00:	f426                	sd	s1,40(sp)
    80001f02:	f04a                	sd	s2,32(sp)
    80001f04:	ec4e                	sd	s3,24(sp)
    80001f06:	e852                	sd	s4,16(sp)
    80001f08:	e456                	sd	s5,8(sp)
    80001f0a:	e05a                	sd	s6,0(sp)
    80001f0c:	0080                	addi	s0,sp,64
    80001f0e:	8792                	mv	a5,tp
  int id = r_tp();
    80001f10:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f12:	00779a93          	slli	s5,a5,0x7
    80001f16:	0000f717          	auipc	a4,0xf
    80001f1a:	38a70713          	addi	a4,a4,906 # 800112a0 <pid_lock>
    80001f1e:	9756                	add	a4,a4,s5
    80001f20:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f24:	0000f717          	auipc	a4,0xf
    80001f28:	3b470713          	addi	a4,a4,948 # 800112d8 <cpus+0x8>
    80001f2c:	9aba                	add	s5,s5,a4
      if (p->state == RUNNABLE)
    80001f2e:	498d                	li	s3,3
        p->state = RUNNING;
    80001f30:	4b11                	li	s6,4
        c->proc = p;
    80001f32:	079e                	slli	a5,a5,0x7
    80001f34:	0000fa17          	auipc	s4,0xf
    80001f38:	36ca0a13          	addi	s4,s4,876 # 800112a0 <pid_lock>
    80001f3c:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f3e:	00015917          	auipc	s2,0x15
    80001f42:	39290913          	addi	s2,s2,914 # 800172d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f46:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f4a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f4e:	10079073          	csrw	sstatus,a5
    80001f52:	0000f497          	auipc	s1,0xf
    80001f56:	77e48493          	addi	s1,s1,1918 # 800116d0 <proc>
    80001f5a:	a811                	j	80001f6e <scheduler+0x74>
      release(&p->lock);
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	fffff097          	auipc	ra,0xfffff
    80001f62:	d18080e7          	jalr	-744(ra) # 80000c76 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f66:	17048493          	addi	s1,s1,368
    80001f6a:	fd248ee3          	beq	s1,s2,80001f46 <scheduler+0x4c>
      acquire(&p->lock);
    80001f6e:	8526                	mv	a0,s1
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c52080e7          	jalr	-942(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80001f78:	4c9c                	lw	a5,24(s1)
    80001f7a:	ff3791e3          	bne	a5,s3,80001f5c <scheduler+0x62>
        p->state = RUNNING;
    80001f7e:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f82:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f86:	06048593          	addi	a1,s1,96
    80001f8a:	8556                	mv	a0,s5
    80001f8c:	00000097          	auipc	ra,0x0
    80001f90:	6b8080e7          	jalr	1720(ra) # 80002644 <swtch>
        c->proc = 0;
    80001f94:	020a3823          	sd	zero,48(s4)
    80001f98:	b7d1                	j	80001f5c <scheduler+0x62>

0000000080001f9a <sched>:
{
    80001f9a:	7179                	addi	sp,sp,-48
    80001f9c:	f406                	sd	ra,40(sp)
    80001f9e:	f022                	sd	s0,32(sp)
    80001fa0:	ec26                	sd	s1,24(sp)
    80001fa2:	e84a                	sd	s2,16(sp)
    80001fa4:	e44e                	sd	s3,8(sp)
    80001fa6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	9ea080e7          	jalr	-1558(ra) # 80001992 <myproc>
    80001fb0:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	b96080e7          	jalr	-1130(ra) # 80000b48 <holding>
    80001fba:	c93d                	beqz	a0,80002030 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fbc:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fbe:	2781                	sext.w	a5,a5
    80001fc0:	079e                	slli	a5,a5,0x7
    80001fc2:	0000f717          	auipc	a4,0xf
    80001fc6:	2de70713          	addi	a4,a4,734 # 800112a0 <pid_lock>
    80001fca:	97ba                	add	a5,a5,a4
    80001fcc:	0a87a703          	lw	a4,168(a5)
    80001fd0:	4785                	li	a5,1
    80001fd2:	06f71763          	bne	a4,a5,80002040 <sched+0xa6>
  if (p->state == RUNNING)
    80001fd6:	4c98                	lw	a4,24(s1)
    80001fd8:	4791                	li	a5,4
    80001fda:	06f70b63          	beq	a4,a5,80002050 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fde:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fe2:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001fe4:	efb5                	bnez	a5,80002060 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fe6:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fe8:	0000f917          	auipc	s2,0xf
    80001fec:	2b890913          	addi	s2,s2,696 # 800112a0 <pid_lock>
    80001ff0:	2781                	sext.w	a5,a5
    80001ff2:	079e                	slli	a5,a5,0x7
    80001ff4:	97ca                	add	a5,a5,s2
    80001ff6:	0ac7a983          	lw	s3,172(a5)
    80001ffa:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ffc:	2781                	sext.w	a5,a5
    80001ffe:	079e                	slli	a5,a5,0x7
    80002000:	0000f597          	auipc	a1,0xf
    80002004:	2d858593          	addi	a1,a1,728 # 800112d8 <cpus+0x8>
    80002008:	95be                	add	a1,a1,a5
    8000200a:	06048513          	addi	a0,s1,96
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	636080e7          	jalr	1590(ra) # 80002644 <swtch>
    80002016:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002018:	2781                	sext.w	a5,a5
    8000201a:	079e                	slli	a5,a5,0x7
    8000201c:	97ca                	add	a5,a5,s2
    8000201e:	0b37a623          	sw	s3,172(a5)
}
    80002022:	70a2                	ld	ra,40(sp)
    80002024:	7402                	ld	s0,32(sp)
    80002026:	64e2                	ld	s1,24(sp)
    80002028:	6942                	ld	s2,16(sp)
    8000202a:	69a2                	ld	s3,8(sp)
    8000202c:	6145                	addi	sp,sp,48
    8000202e:	8082                	ret
    panic("sched p->lock");
    80002030:	00006517          	auipc	a0,0x6
    80002034:	1d050513          	addi	a0,a0,464 # 80008200 <digits+0x1c0>
    80002038:	ffffe097          	auipc	ra,0xffffe
    8000203c:	4f2080e7          	jalr	1266(ra) # 8000052a <panic>
    panic("sched locks");
    80002040:	00006517          	auipc	a0,0x6
    80002044:	1d050513          	addi	a0,a0,464 # 80008210 <digits+0x1d0>
    80002048:	ffffe097          	auipc	ra,0xffffe
    8000204c:	4e2080e7          	jalr	1250(ra) # 8000052a <panic>
    panic("sched running");
    80002050:	00006517          	auipc	a0,0x6
    80002054:	1d050513          	addi	a0,a0,464 # 80008220 <digits+0x1e0>
    80002058:	ffffe097          	auipc	ra,0xffffe
    8000205c:	4d2080e7          	jalr	1234(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002060:	00006517          	auipc	a0,0x6
    80002064:	1d050513          	addi	a0,a0,464 # 80008230 <digits+0x1f0>
    80002068:	ffffe097          	auipc	ra,0xffffe
    8000206c:	4c2080e7          	jalr	1218(ra) # 8000052a <panic>

0000000080002070 <yield>:
{
    80002070:	1101                	addi	sp,sp,-32
    80002072:	ec06                	sd	ra,24(sp)
    80002074:	e822                	sd	s0,16(sp)
    80002076:	e426                	sd	s1,8(sp)
    80002078:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000207a:	00000097          	auipc	ra,0x0
    8000207e:	918080e7          	jalr	-1768(ra) # 80001992 <myproc>
    80002082:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002084:	fffff097          	auipc	ra,0xfffff
    80002088:	b3e080e7          	jalr	-1218(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    8000208c:	478d                	li	a5,3
    8000208e:	cc9c                	sw	a5,24(s1)
  sched();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	f0a080e7          	jalr	-246(ra) # 80001f9a <sched>
  release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bdc080e7          	jalr	-1060(ra) # 80000c76 <release>
}
    800020a2:	60e2                	ld	ra,24(sp)
    800020a4:	6442                	ld	s0,16(sp)
    800020a6:	64a2                	ld	s1,8(sp)
    800020a8:	6105                	addi	sp,sp,32
    800020aa:	8082                	ret

00000000800020ac <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020ac:	7179                	addi	sp,sp,-48
    800020ae:	f406                	sd	ra,40(sp)
    800020b0:	f022                	sd	s0,32(sp)
    800020b2:	ec26                	sd	s1,24(sp)
    800020b4:	e84a                	sd	s2,16(sp)
    800020b6:	e44e                	sd	s3,8(sp)
    800020b8:	1800                	addi	s0,sp,48
    800020ba:	89aa                	mv	s3,a0
    800020bc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	8d4080e7          	jalr	-1836(ra) # 80001992 <myproc>
    800020c6:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	afa080e7          	jalr	-1286(ra) # 80000bc2 <acquire>
  release(lk);
    800020d0:	854a                	mv	a0,s2
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	ba4080e7          	jalr	-1116(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020da:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020de:	4789                	li	a5,2
    800020e0:	cc9c                	sw	a5,24(s1)

  sched();
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	eb8080e7          	jalr	-328(ra) # 80001f9a <sched>

  // Tidy up.
  p->chan = 0;
    800020ea:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ee:	8526                	mv	a0,s1
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b86080e7          	jalr	-1146(ra) # 80000c76 <release>
  acquire(lk);
    800020f8:	854a                	mv	a0,s2
    800020fa:	fffff097          	auipc	ra,0xfffff
    800020fe:	ac8080e7          	jalr	-1336(ra) # 80000bc2 <acquire>
}
    80002102:	70a2                	ld	ra,40(sp)
    80002104:	7402                	ld	s0,32(sp)
    80002106:	64e2                	ld	s1,24(sp)
    80002108:	6942                	ld	s2,16(sp)
    8000210a:	69a2                	ld	s3,8(sp)
    8000210c:	6145                	addi	sp,sp,48
    8000210e:	8082                	ret

0000000080002110 <wait>:
{
    80002110:	715d                	addi	sp,sp,-80
    80002112:	e486                	sd	ra,72(sp)
    80002114:	e0a2                	sd	s0,64(sp)
    80002116:	fc26                	sd	s1,56(sp)
    80002118:	f84a                	sd	s2,48(sp)
    8000211a:	f44e                	sd	s3,40(sp)
    8000211c:	f052                	sd	s4,32(sp)
    8000211e:	ec56                	sd	s5,24(sp)
    80002120:	e85a                	sd	s6,16(sp)
    80002122:	e45e                	sd	s7,8(sp)
    80002124:	e062                	sd	s8,0(sp)
    80002126:	0880                	addi	s0,sp,80
    80002128:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	868080e7          	jalr	-1944(ra) # 80001992 <myproc>
    80002132:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002134:	0000f517          	auipc	a0,0xf
    80002138:	18450513          	addi	a0,a0,388 # 800112b8 <wait_lock>
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	a86080e7          	jalr	-1402(ra) # 80000bc2 <acquire>
    havekids = 0;
    80002144:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    80002146:	4a15                	li	s4,5
        havekids = 1;
    80002148:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000214a:	00015997          	auipc	s3,0x15
    8000214e:	18698993          	addi	s3,s3,390 # 800172d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002152:	0000fc17          	auipc	s8,0xf
    80002156:	166c0c13          	addi	s8,s8,358 # 800112b8 <wait_lock>
    havekids = 0;
    8000215a:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    8000215c:	0000f497          	auipc	s1,0xf
    80002160:	57448493          	addi	s1,s1,1396 # 800116d0 <proc>
    80002164:	a0bd                	j	800021d2 <wait+0xc2>
          pid = np->pid;
    80002166:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000216a:	000b0e63          	beqz	s6,80002186 <wait+0x76>
    8000216e:	4691                	li	a3,4
    80002170:	02c48613          	addi	a2,s1,44
    80002174:	85da                	mv	a1,s6
    80002176:	05093503          	ld	a0,80(s2)
    8000217a:	fffff097          	auipc	ra,0xfffff
    8000217e:	4c4080e7          	jalr	1220(ra) # 8000163e <copyout>
    80002182:	02054563          	bltz	a0,800021ac <wait+0x9c>
          freeproc(np);
    80002186:	8526                	mv	a0,s1
    80002188:	00000097          	auipc	ra,0x0
    8000218c:	9bc080e7          	jalr	-1604(ra) # 80001b44 <freeproc>
          release(&np->lock);
    80002190:	8526                	mv	a0,s1
    80002192:	fffff097          	auipc	ra,0xfffff
    80002196:	ae4080e7          	jalr	-1308(ra) # 80000c76 <release>
          release(&wait_lock);
    8000219a:	0000f517          	auipc	a0,0xf
    8000219e:	11e50513          	addi	a0,a0,286 # 800112b8 <wait_lock>
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	ad4080e7          	jalr	-1324(ra) # 80000c76 <release>
          return pid;
    800021aa:	a09d                	j	80002210 <wait+0x100>
            release(&np->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	ac8080e7          	jalr	-1336(ra) # 80000c76 <release>
            release(&wait_lock);
    800021b6:	0000f517          	auipc	a0,0xf
    800021ba:	10250513          	addi	a0,a0,258 # 800112b8 <wait_lock>
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	ab8080e7          	jalr	-1352(ra) # 80000c76 <release>
            return -1;
    800021c6:	59fd                	li	s3,-1
    800021c8:	a0a1                	j	80002210 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021ca:	17048493          	addi	s1,s1,368
    800021ce:	03348463          	beq	s1,s3,800021f6 <wait+0xe6>
      if (np->parent == p)
    800021d2:	7c9c                	ld	a5,56(s1)
    800021d4:	ff279be3          	bne	a5,s2,800021ca <wait+0xba>
        acquire(&np->lock);
    800021d8:	8526                	mv	a0,s1
    800021da:	fffff097          	auipc	ra,0xfffff
    800021de:	9e8080e7          	jalr	-1560(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800021e2:	4c9c                	lw	a5,24(s1)
    800021e4:	f94781e3          	beq	a5,s4,80002166 <wait+0x56>
        release(&np->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	a8c080e7          	jalr	-1396(ra) # 80000c76 <release>
        havekids = 1;
    800021f2:	8756                	mv	a4,s5
    800021f4:	bfd9                	j	800021ca <wait+0xba>
    if (!havekids || p->killed)
    800021f6:	c701                	beqz	a4,800021fe <wait+0xee>
    800021f8:	02892783          	lw	a5,40(s2)
    800021fc:	c79d                	beqz	a5,8000222a <wait+0x11a>
      release(&wait_lock);
    800021fe:	0000f517          	auipc	a0,0xf
    80002202:	0ba50513          	addi	a0,a0,186 # 800112b8 <wait_lock>
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a70080e7          	jalr	-1424(ra) # 80000c76 <release>
      return -1;
    8000220e:	59fd                	li	s3,-1
}
    80002210:	854e                	mv	a0,s3
    80002212:	60a6                	ld	ra,72(sp)
    80002214:	6406                	ld	s0,64(sp)
    80002216:	74e2                	ld	s1,56(sp)
    80002218:	7942                	ld	s2,48(sp)
    8000221a:	79a2                	ld	s3,40(sp)
    8000221c:	7a02                	ld	s4,32(sp)
    8000221e:	6ae2                	ld	s5,24(sp)
    80002220:	6b42                	ld	s6,16(sp)
    80002222:	6ba2                	ld	s7,8(sp)
    80002224:	6c02                	ld	s8,0(sp)
    80002226:	6161                	addi	sp,sp,80
    80002228:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    8000222a:	85e2                	mv	a1,s8
    8000222c:	854a                	mv	a0,s2
    8000222e:	00000097          	auipc	ra,0x0
    80002232:	e7e080e7          	jalr	-386(ra) # 800020ac <sleep>
    havekids = 0;
    80002236:	b715                	j	8000215a <wait+0x4a>

0000000080002238 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002238:	7139                	addi	sp,sp,-64
    8000223a:	fc06                	sd	ra,56(sp)
    8000223c:	f822                	sd	s0,48(sp)
    8000223e:	f426                	sd	s1,40(sp)
    80002240:	f04a                	sd	s2,32(sp)
    80002242:	ec4e                	sd	s3,24(sp)
    80002244:	e852                	sd	s4,16(sp)
    80002246:	e456                	sd	s5,8(sp)
    80002248:	0080                	addi	s0,sp,64
    8000224a:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000224c:	0000f497          	auipc	s1,0xf
    80002250:	48448493          	addi	s1,s1,1156 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002254:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002256:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002258:	00015917          	auipc	s2,0x15
    8000225c:	07890913          	addi	s2,s2,120 # 800172d0 <tickslock>
    80002260:	a811                	j	80002274 <wakeup+0x3c>
      }
      release(&p->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a12080e7          	jalr	-1518(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000226c:	17048493          	addi	s1,s1,368
    80002270:	03248663          	beq	s1,s2,8000229c <wakeup+0x64>
    if (p != myproc())
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	71e080e7          	jalr	1822(ra) # 80001992 <myproc>
    8000227c:	fea488e3          	beq	s1,a0,8000226c <wakeup+0x34>
      acquire(&p->lock);
    80002280:	8526                	mv	a0,s1
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	940080e7          	jalr	-1728(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000228a:	4c9c                	lw	a5,24(s1)
    8000228c:	fd379be3          	bne	a5,s3,80002262 <wakeup+0x2a>
    80002290:	709c                	ld	a5,32(s1)
    80002292:	fd4798e3          	bne	a5,s4,80002262 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002296:	0154ac23          	sw	s5,24(s1)
    8000229a:	b7e1                	j	80002262 <wakeup+0x2a>
    }
  }
}
    8000229c:	70e2                	ld	ra,56(sp)
    8000229e:	7442                	ld	s0,48(sp)
    800022a0:	74a2                	ld	s1,40(sp)
    800022a2:	7902                	ld	s2,32(sp)
    800022a4:	69e2                	ld	s3,24(sp)
    800022a6:	6a42                	ld	s4,16(sp)
    800022a8:	6aa2                	ld	s5,8(sp)
    800022aa:	6121                	addi	sp,sp,64
    800022ac:	8082                	ret

00000000800022ae <reparent>:
{
    800022ae:	7179                	addi	sp,sp,-48
    800022b0:	f406                	sd	ra,40(sp)
    800022b2:	f022                	sd	s0,32(sp)
    800022b4:	ec26                	sd	s1,24(sp)
    800022b6:	e84a                	sd	s2,16(sp)
    800022b8:	e44e                	sd	s3,8(sp)
    800022ba:	e052                	sd	s4,0(sp)
    800022bc:	1800                	addi	s0,sp,48
    800022be:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022c0:	0000f497          	auipc	s1,0xf
    800022c4:	41048493          	addi	s1,s1,1040 # 800116d0 <proc>
      pp->parent = initproc;
    800022c8:	00007a17          	auipc	s4,0x7
    800022cc:	d60a0a13          	addi	s4,s4,-672 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022d0:	00015997          	auipc	s3,0x15
    800022d4:	00098993          	mv	s3,s3
    800022d8:	a029                	j	800022e2 <reparent+0x34>
    800022da:	17048493          	addi	s1,s1,368
    800022de:	01348d63          	beq	s1,s3,800022f8 <reparent+0x4a>
    if (pp->parent == p)
    800022e2:	7c9c                	ld	a5,56(s1)
    800022e4:	ff279be3          	bne	a5,s2,800022da <reparent+0x2c>
      pp->parent = initproc;
    800022e8:	000a3503          	ld	a0,0(s4)
    800022ec:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022ee:	00000097          	auipc	ra,0x0
    800022f2:	f4a080e7          	jalr	-182(ra) # 80002238 <wakeup>
    800022f6:	b7d5                	j	800022da <reparent+0x2c>
}
    800022f8:	70a2                	ld	ra,40(sp)
    800022fa:	7402                	ld	s0,32(sp)
    800022fc:	64e2                	ld	s1,24(sp)
    800022fe:	6942                	ld	s2,16(sp)
    80002300:	69a2                	ld	s3,8(sp)
    80002302:	6a02                	ld	s4,0(sp)
    80002304:	6145                	addi	sp,sp,48
    80002306:	8082                	ret

0000000080002308 <exit>:
{
    80002308:	7179                	addi	sp,sp,-48
    8000230a:	f406                	sd	ra,40(sp)
    8000230c:	f022                	sd	s0,32(sp)
    8000230e:	ec26                	sd	s1,24(sp)
    80002310:	e84a                	sd	s2,16(sp)
    80002312:	e44e                	sd	s3,8(sp)
    80002314:	e052                	sd	s4,0(sp)
    80002316:	1800                	addi	s0,sp,48
    80002318:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	678080e7          	jalr	1656(ra) # 80001992 <myproc>
    80002322:	89aa                	mv	s3,a0
  acquire(&tickslock);
    80002324:	00015517          	auipc	a0,0x15
    80002328:	fac50513          	addi	a0,a0,-84 # 800172d0 <tickslock>
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	896080e7          	jalr	-1898(ra) # 80000bc2 <acquire>
  p->performance->ttime = ticks;
    80002334:	1689b783          	ld	a5,360(s3) # 80017438 <bcache+0x150>
    80002338:	00007717          	auipc	a4,0x7
    8000233c:	cf872703          	lw	a4,-776(a4) # 80009030 <ticks>
    80002340:	c3d8                	sw	a4,4(a5)
  release(&tickslock);
    80002342:	00015517          	auipc	a0,0x15
    80002346:	f8e50513          	addi	a0,a0,-114 # 800172d0 <tickslock>
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	92c080e7          	jalr	-1748(ra) # 80000c76 <release>
  if (p == initproc)
    80002352:	00007797          	auipc	a5,0x7
    80002356:	cd67b783          	ld	a5,-810(a5) # 80009028 <initproc>
    8000235a:	0d098493          	addi	s1,s3,208
    8000235e:	15098913          	addi	s2,s3,336
    80002362:	03379363          	bne	a5,s3,80002388 <exit+0x80>
    panic("init exiting");
    80002366:	00006517          	auipc	a0,0x6
    8000236a:	ee250513          	addi	a0,a0,-286 # 80008248 <digits+0x208>
    8000236e:	ffffe097          	auipc	ra,0xffffe
    80002372:	1bc080e7          	jalr	444(ra) # 8000052a <panic>
      fileclose(f);
    80002376:	00002097          	auipc	ra,0x2
    8000237a:	354080e7          	jalr	852(ra) # 800046ca <fileclose>
      p->ofile[fd] = 0;
    8000237e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002382:	04a1                	addi	s1,s1,8
    80002384:	01248563          	beq	s1,s2,8000238e <exit+0x86>
    if (p->ofile[fd])
    80002388:	6088                	ld	a0,0(s1)
    8000238a:	f575                	bnez	a0,80002376 <exit+0x6e>
    8000238c:	bfdd                	j	80002382 <exit+0x7a>
  begin_op();
    8000238e:	00002097          	auipc	ra,0x2
    80002392:	e70080e7          	jalr	-400(ra) # 800041fe <begin_op>
  iput(p->cwd);
    80002396:	1509b503          	ld	a0,336(s3)
    8000239a:	00001097          	auipc	ra,0x1
    8000239e:	648080e7          	jalr	1608(ra) # 800039e2 <iput>
  end_op();
    800023a2:	00002097          	auipc	ra,0x2
    800023a6:	edc080e7          	jalr	-292(ra) # 8000427e <end_op>
  p->cwd = 0;
    800023aa:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023ae:	0000f497          	auipc	s1,0xf
    800023b2:	f0a48493          	addi	s1,s1,-246 # 800112b8 <wait_lock>
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	80a080e7          	jalr	-2038(ra) # 80000bc2 <acquire>
  reparent(p);
    800023c0:	854e                	mv	a0,s3
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	eec080e7          	jalr	-276(ra) # 800022ae <reparent>
  wakeup(p->parent);
    800023ca:	0389b503          	ld	a0,56(s3)
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	e6a080e7          	jalr	-406(ra) # 80002238 <wakeup>
  acquire(&p->lock);
    800023d6:	854e                	mv	a0,s3
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	7ea080e7          	jalr	2026(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800023e0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023e4:	4795                	li	a5,5
    800023e6:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023ea:	8526                	mv	a0,s1
    800023ec:	fffff097          	auipc	ra,0xfffff
    800023f0:	88a080e7          	jalr	-1910(ra) # 80000c76 <release>
  sched();
    800023f4:	00000097          	auipc	ra,0x0
    800023f8:	ba6080e7          	jalr	-1114(ra) # 80001f9a <sched>
  panic("zombie exit");
    800023fc:	00006517          	auipc	a0,0x6
    80002400:	e5c50513          	addi	a0,a0,-420 # 80008258 <digits+0x218>
    80002404:	ffffe097          	auipc	ra,0xffffe
    80002408:	126080e7          	jalr	294(ra) # 8000052a <panic>

000000008000240c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000240c:	7179                	addi	sp,sp,-48
    8000240e:	f406                	sd	ra,40(sp)
    80002410:	f022                	sd	s0,32(sp)
    80002412:	ec26                	sd	s1,24(sp)
    80002414:	e84a                	sd	s2,16(sp)
    80002416:	e44e                	sd	s3,8(sp)
    80002418:	1800                	addi	s0,sp,48
    8000241a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000241c:	0000f497          	auipc	s1,0xf
    80002420:	2b448493          	addi	s1,s1,692 # 800116d0 <proc>
    80002424:	00015997          	auipc	s3,0x15
    80002428:	eac98993          	addi	s3,s3,-340 # 800172d0 <tickslock>
  {
    acquire(&p->lock);
    8000242c:	8526                	mv	a0,s1
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	794080e7          	jalr	1940(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002436:	589c                	lw	a5,48(s1)
    80002438:	01278d63          	beq	a5,s2,80002452 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	838080e7          	jalr	-1992(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002446:	17048493          	addi	s1,s1,368
    8000244a:	ff3491e3          	bne	s1,s3,8000242c <kill+0x20>
  }
  return -1;
    8000244e:	557d                	li	a0,-1
    80002450:	a829                	j	8000246a <kill+0x5e>
      p->killed = 1;
    80002452:	4785                	li	a5,1
    80002454:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002456:	4c98                	lw	a4,24(s1)
    80002458:	4789                	li	a5,2
    8000245a:	00f70f63          	beq	a4,a5,80002478 <kill+0x6c>
      release(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	816080e7          	jalr	-2026(ra) # 80000c76 <release>
      return 0;
    80002468:	4501                	li	a0,0
}
    8000246a:	70a2                	ld	ra,40(sp)
    8000246c:	7402                	ld	s0,32(sp)
    8000246e:	64e2                	ld	s1,24(sp)
    80002470:	6942                	ld	s2,16(sp)
    80002472:	69a2                	ld	s3,8(sp)
    80002474:	6145                	addi	sp,sp,48
    80002476:	8082                	ret
        p->state = RUNNABLE;
    80002478:	478d                	li	a5,3
    8000247a:	cc9c                	sw	a5,24(s1)
    8000247c:	b7cd                	j	8000245e <kill+0x52>

000000008000247e <trace>:

int trace(int mask, int pid)
{
    8000247e:	7179                	addi	sp,sp,-48
    80002480:	f406                	sd	ra,40(sp)
    80002482:	f022                	sd	s0,32(sp)
    80002484:	ec26                	sd	s1,24(sp)
    80002486:	e84a                	sd	s2,16(sp)
    80002488:	e44e                	sd	s3,8(sp)
    8000248a:	e052                	sd	s4,0(sp)
    8000248c:	1800                	addi	s0,sp,48
    8000248e:	8a2a                	mv	s4,a0
    80002490:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	23e48493          	addi	s1,s1,574 # 800116d0 <proc>
    8000249a:	00015997          	auipc	s3,0x15
    8000249e:	e3698993          	addi	s3,s3,-458 # 800172d0 <tickslock>
  {
    acquire(&p->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	71e080e7          	jalr	1822(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    800024ac:	589c                	lw	a5,48(s1)
    800024ae:	01278d63          	beq	a5,s2,800024c8 <trace+0x4a>
    {
      p->traceMask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7c2080e7          	jalr	1986(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800024bc:	17048493          	addi	s1,s1,368
    800024c0:	ff3491e3          	bne	s1,s3,800024a2 <trace+0x24>
  }
  return -1;
    800024c4:	557d                	li	a0,-1
    800024c6:	a809                	j	800024d8 <trace+0x5a>
      p->traceMask = mask;
    800024c8:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    800024cc:	8526                	mv	a0,s1
    800024ce:	ffffe097          	auipc	ra,0xffffe
    800024d2:	7a8080e7          	jalr	1960(ra) # 80000c76 <release>
      return 0;
    800024d6:	4501                	li	a0,0
}
    800024d8:	70a2                	ld	ra,40(sp)
    800024da:	7402                	ld	s0,32(sp)
    800024dc:	64e2                	ld	s1,24(sp)
    800024de:	6942                	ld	s2,16(sp)
    800024e0:	69a2                	ld	s3,8(sp)
    800024e2:	6a02                	ld	s4,0(sp)
    800024e4:	6145                	addi	sp,sp,48
    800024e6:	8082                	ret

00000000800024e8 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024e8:	7179                	addi	sp,sp,-48
    800024ea:	f406                	sd	ra,40(sp)
    800024ec:	f022                	sd	s0,32(sp)
    800024ee:	ec26                	sd	s1,24(sp)
    800024f0:	e84a                	sd	s2,16(sp)
    800024f2:	e44e                	sd	s3,8(sp)
    800024f4:	e052                	sd	s4,0(sp)
    800024f6:	1800                	addi	s0,sp,48
    800024f8:	84aa                	mv	s1,a0
    800024fa:	892e                	mv	s2,a1
    800024fc:	89b2                	mv	s3,a2
    800024fe:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	492080e7          	jalr	1170(ra) # 80001992 <myproc>
  if (user_dst)
    80002508:	c08d                	beqz	s1,8000252a <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    8000250a:	86d2                	mv	a3,s4
    8000250c:	864e                	mv	a2,s3
    8000250e:	85ca                	mv	a1,s2
    80002510:	6928                	ld	a0,80(a0)
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	12c080e7          	jalr	300(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000251a:	70a2                	ld	ra,40(sp)
    8000251c:	7402                	ld	s0,32(sp)
    8000251e:	64e2                	ld	s1,24(sp)
    80002520:	6942                	ld	s2,16(sp)
    80002522:	69a2                	ld	s3,8(sp)
    80002524:	6a02                	ld	s4,0(sp)
    80002526:	6145                	addi	sp,sp,48
    80002528:	8082                	ret
    memmove((char *)dst, src, len);
    8000252a:	000a061b          	sext.w	a2,s4
    8000252e:	85ce                	mv	a1,s3
    80002530:	854a                	mv	a0,s2
    80002532:	ffffe097          	auipc	ra,0xffffe
    80002536:	7e8080e7          	jalr	2024(ra) # 80000d1a <memmove>
    return 0;
    8000253a:	8526                	mv	a0,s1
    8000253c:	bff9                	j	8000251a <either_copyout+0x32>

000000008000253e <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000253e:	7179                	addi	sp,sp,-48
    80002540:	f406                	sd	ra,40(sp)
    80002542:	f022                	sd	s0,32(sp)
    80002544:	ec26                	sd	s1,24(sp)
    80002546:	e84a                	sd	s2,16(sp)
    80002548:	e44e                	sd	s3,8(sp)
    8000254a:	e052                	sd	s4,0(sp)
    8000254c:	1800                	addi	s0,sp,48
    8000254e:	892a                	mv	s2,a0
    80002550:	84ae                	mv	s1,a1
    80002552:	89b2                	mv	s3,a2
    80002554:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	43c080e7          	jalr	1084(ra) # 80001992 <myproc>
  if (user_src)
    8000255e:	c08d                	beqz	s1,80002580 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002560:	86d2                	mv	a3,s4
    80002562:	864e                	mv	a2,s3
    80002564:	85ca                	mv	a1,s2
    80002566:	6928                	ld	a0,80(a0)
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	162080e7          	jalr	354(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002570:	70a2                	ld	ra,40(sp)
    80002572:	7402                	ld	s0,32(sp)
    80002574:	64e2                	ld	s1,24(sp)
    80002576:	6942                	ld	s2,16(sp)
    80002578:	69a2                	ld	s3,8(sp)
    8000257a:	6a02                	ld	s4,0(sp)
    8000257c:	6145                	addi	sp,sp,48
    8000257e:	8082                	ret
    memmove(dst, (char *)src, len);
    80002580:	000a061b          	sext.w	a2,s4
    80002584:	85ce                	mv	a1,s3
    80002586:	854a                	mv	a0,s2
    80002588:	ffffe097          	auipc	ra,0xffffe
    8000258c:	792080e7          	jalr	1938(ra) # 80000d1a <memmove>
    return 0;
    80002590:	8526                	mv	a0,s1
    80002592:	bff9                	j	80002570 <either_copyin+0x32>

0000000080002594 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002594:	715d                	addi	sp,sp,-80
    80002596:	e486                	sd	ra,72(sp)
    80002598:	e0a2                	sd	s0,64(sp)
    8000259a:	fc26                	sd	s1,56(sp)
    8000259c:	f84a                	sd	s2,48(sp)
    8000259e:	f44e                	sd	s3,40(sp)
    800025a0:	f052                	sd	s4,32(sp)
    800025a2:	ec56                	sd	s5,24(sp)
    800025a4:	e85a                	sd	s6,16(sp)
    800025a6:	e45e                	sd	s7,8(sp)
    800025a8:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    800025aa:	00006517          	auipc	a0,0x6
    800025ae:	b1e50513          	addi	a0,a0,-1250 # 800080c8 <digits+0x88>
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	fc2080e7          	jalr	-62(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800025ba:	0000f497          	auipc	s1,0xf
    800025be:	26e48493          	addi	s1,s1,622 # 80011828 <proc+0x158>
    800025c2:	00015917          	auipc	s2,0x15
    800025c6:	e6690913          	addi	s2,s2,-410 # 80017428 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ca:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025cc:	00006997          	auipc	s3,0x6
    800025d0:	c9c98993          	addi	s3,s3,-868 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025d4:	00006a97          	auipc	s5,0x6
    800025d8:	c9ca8a93          	addi	s5,s5,-868 # 80008270 <digits+0x230>
    printf("\n");
    800025dc:	00006a17          	auipc	s4,0x6
    800025e0:	aeca0a13          	addi	s4,s4,-1300 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025e4:	00006b97          	auipc	s7,0x6
    800025e8:	cc4b8b93          	addi	s7,s7,-828 # 800082a8 <states.0>
    800025ec:	a00d                	j	8000260e <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ee:	ed86a583          	lw	a1,-296(a3)
    800025f2:	8556                	mv	a0,s5
    800025f4:	ffffe097          	auipc	ra,0xffffe
    800025f8:	f80080e7          	jalr	-128(ra) # 80000574 <printf>
    printf("\n");
    800025fc:	8552                	mv	a0,s4
    800025fe:	ffffe097          	auipc	ra,0xffffe
    80002602:	f76080e7          	jalr	-138(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002606:	17048493          	addi	s1,s1,368
    8000260a:	03248263          	beq	s1,s2,8000262e <procdump+0x9a>
    if (p->state == UNUSED)
    8000260e:	86a6                	mv	a3,s1
    80002610:	ec04a783          	lw	a5,-320(s1)
    80002614:	dbed                	beqz	a5,80002606 <procdump+0x72>
      state = "???";
    80002616:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002618:	fcfb6be3          	bltu	s6,a5,800025ee <procdump+0x5a>
    8000261c:	02079713          	slli	a4,a5,0x20
    80002620:	01d75793          	srli	a5,a4,0x1d
    80002624:	97de                	add	a5,a5,s7
    80002626:	6390                	ld	a2,0(a5)
    80002628:	f279                	bnez	a2,800025ee <procdump+0x5a>
      state = "???";
    8000262a:	864e                	mv	a2,s3
    8000262c:	b7c9                	j	800025ee <procdump+0x5a>
  }
}
    8000262e:	60a6                	ld	ra,72(sp)
    80002630:	6406                	ld	s0,64(sp)
    80002632:	74e2                	ld	s1,56(sp)
    80002634:	7942                	ld	s2,48(sp)
    80002636:	79a2                	ld	s3,40(sp)
    80002638:	7a02                	ld	s4,32(sp)
    8000263a:	6ae2                	ld	s5,24(sp)
    8000263c:	6b42                	ld	s6,16(sp)
    8000263e:	6ba2                	ld	s7,8(sp)
    80002640:	6161                	addi	sp,sp,80
    80002642:	8082                	ret

0000000080002644 <swtch>:
    80002644:	00153023          	sd	ra,0(a0)
    80002648:	00253423          	sd	sp,8(a0)
    8000264c:	e900                	sd	s0,16(a0)
    8000264e:	ed04                	sd	s1,24(a0)
    80002650:	03253023          	sd	s2,32(a0)
    80002654:	03353423          	sd	s3,40(a0)
    80002658:	03453823          	sd	s4,48(a0)
    8000265c:	03553c23          	sd	s5,56(a0)
    80002660:	05653023          	sd	s6,64(a0)
    80002664:	05753423          	sd	s7,72(a0)
    80002668:	05853823          	sd	s8,80(a0)
    8000266c:	05953c23          	sd	s9,88(a0)
    80002670:	07a53023          	sd	s10,96(a0)
    80002674:	07b53423          	sd	s11,104(a0)
    80002678:	0005b083          	ld	ra,0(a1)
    8000267c:	0085b103          	ld	sp,8(a1)
    80002680:	6980                	ld	s0,16(a1)
    80002682:	6d84                	ld	s1,24(a1)
    80002684:	0205b903          	ld	s2,32(a1)
    80002688:	0285b983          	ld	s3,40(a1)
    8000268c:	0305ba03          	ld	s4,48(a1)
    80002690:	0385ba83          	ld	s5,56(a1)
    80002694:	0405bb03          	ld	s6,64(a1)
    80002698:	0485bb83          	ld	s7,72(a1)
    8000269c:	0505bc03          	ld	s8,80(a1)
    800026a0:	0585bc83          	ld	s9,88(a1)
    800026a4:	0605bd03          	ld	s10,96(a1)
    800026a8:	0685bd83          	ld	s11,104(a1)
    800026ac:	8082                	ret

00000000800026ae <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026ae:	1141                	addi	sp,sp,-16
    800026b0:	e406                	sd	ra,8(sp)
    800026b2:	e022                	sd	s0,0(sp)
    800026b4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026b6:	00006597          	auipc	a1,0x6
    800026ba:	c2258593          	addi	a1,a1,-990 # 800082d8 <states.0+0x30>
    800026be:	00015517          	auipc	a0,0x15
    800026c2:	c1250513          	addi	a0,a0,-1006 # 800172d0 <tickslock>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	46c080e7          	jalr	1132(ra) # 80000b32 <initlock>
}
    800026ce:	60a2                	ld	ra,8(sp)
    800026d0:	6402                	ld	s0,0(sp)
    800026d2:	0141                	addi	sp,sp,16
    800026d4:	8082                	ret

00000000800026d6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026d6:	1141                	addi	sp,sp,-16
    800026d8:	e422                	sd	s0,8(sp)
    800026da:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026dc:	00003797          	auipc	a5,0x3
    800026e0:	61478793          	addi	a5,a5,1556 # 80005cf0 <kernelvec>
    800026e4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026e8:	6422                	ld	s0,8(sp)
    800026ea:	0141                	addi	sp,sp,16
    800026ec:	8082                	ret

00000000800026ee <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ee:	1141                	addi	sp,sp,-16
    800026f0:	e406                	sd	ra,8(sp)
    800026f2:	e022                	sd	s0,0(sp)
    800026f4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	29c080e7          	jalr	668(ra) # 80001992 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002702:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002704:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002708:	00005617          	auipc	a2,0x5
    8000270c:	8f860613          	addi	a2,a2,-1800 # 80007000 <_trampoline>
    80002710:	00005697          	auipc	a3,0x5
    80002714:	8f068693          	addi	a3,a3,-1808 # 80007000 <_trampoline>
    80002718:	8e91                	sub	a3,a3,a2
    8000271a:	040007b7          	lui	a5,0x4000
    8000271e:	17fd                	addi	a5,a5,-1
    80002720:	07b2                	slli	a5,a5,0xc
    80002722:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002724:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002728:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000272a:	180026f3          	csrr	a3,satp
    8000272e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002730:	6d38                	ld	a4,88(a0)
    80002732:	6134                	ld	a3,64(a0)
    80002734:	6585                	lui	a1,0x1
    80002736:	96ae                	add	a3,a3,a1
    80002738:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000273a:	6d38                	ld	a4,88(a0)
    8000273c:	00000697          	auipc	a3,0x0
    80002740:	1c268693          	addi	a3,a3,450 # 800028fe <usertrap>
    80002744:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002746:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002748:	8692                	mv	a3,tp
    8000274a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000274c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002750:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002754:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002758:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000275c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000275e:	6f18                	ld	a4,24(a4)
    80002760:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002764:	692c                	ld	a1,80(a0)
    80002766:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002768:	00005717          	auipc	a4,0x5
    8000276c:	92870713          	addi	a4,a4,-1752 # 80007090 <userret>
    80002770:	8f11                	sub	a4,a4,a2
    80002772:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002774:	577d                	li	a4,-1
    80002776:	177e                	slli	a4,a4,0x3f
    80002778:	8dd9                	or	a1,a1,a4
    8000277a:	02000537          	lui	a0,0x2000
    8000277e:	157d                	addi	a0,a0,-1
    80002780:	0536                	slli	a0,a0,0xd
    80002782:	9782                	jalr	a5
}
    80002784:	60a2                	ld	ra,8(sp)
    80002786:	6402                	ld	s0,0(sp)
    80002788:	0141                	addi	sp,sp,16
    8000278a:	8082                	ret

000000008000278c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000278c:	7139                	addi	sp,sp,-64
    8000278e:	fc06                	sd	ra,56(sp)
    80002790:	f822                	sd	s0,48(sp)
    80002792:	f426                	sd	s1,40(sp)
    80002794:	f04a                	sd	s2,32(sp)
    80002796:	ec4e                	sd	s3,24(sp)
    80002798:	e852                	sd	s4,16(sp)
    8000279a:	e456                	sd	s5,8(sp)
    8000279c:	0080                	addi	s0,sp,64
  acquire(&tickslock);
    8000279e:	00015517          	auipc	a0,0x15
    800027a2:	b3250513          	addi	a0,a0,-1230 # 800172d0 <tickslock>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	41c080e7          	jalr	1052(ra) # 80000bc2 <acquire>
  ticks++;
    800027ae:	00007717          	auipc	a4,0x7
    800027b2:	88270713          	addi	a4,a4,-1918 # 80009030 <ticks>
    800027b6:	431c                	lw	a5,0(a4)
    800027b8:	2785                	addiw	a5,a5,1
    800027ba:	c31c                	sw	a5,0(a4)
  //start add UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
  struct proc *p;
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	050080e7          	jalr	80(ra) # 8000180c <getProc>
    800027c4:	84aa                	mv	s1,a0
    800027c6:	6919                	lui	s2,0x6
    800027c8:	c0090913          	addi	s2,s2,-1024 # 5c00 <_entry-0x7fffa400>
    acquire(&p->lock);

    enum procstate state = p->state;
    switch (state)
    800027cc:	4a8d                	li	s5,3
    800027ce:	4a11                	li	s4,4
    800027d0:	4989                	li	s3,2
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027d2:	a829                	j	800027ec <clockintr+0x60>
      break;
    case SLEEPING:
      p->performance->stime += 1;
      break;
    case RUNNABLE:
      p->performance->retime += 1;
    800027d4:	1684b703          	ld	a4,360(s1)
    800027d8:	475c                	lw	a5,12(a4)
    800027da:	2785                	addiw	a5,a5,1
    800027dc:	c75c                	sw	a5,12(a4)
    case ZOMBIE:   
      break; 
    default:
      break;
    }
    release(&p->lock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	496080e7          	jalr	1174(ra) # 80000c76 <release>
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    800027e8:	17048493          	addi	s1,s1,368
    800027ec:	fffff097          	auipc	ra,0xfffff
    800027f0:	020080e7          	jalr	32(ra) # 8000180c <getProc>
    800027f4:	954a                	add	a0,a0,s2
    800027f6:	02a4fa63          	bgeu	s1,a0,8000282a <clockintr+0x9e>
    acquire(&p->lock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	3c6080e7          	jalr	966(ra) # 80000bc2 <acquire>
    enum procstate state = p->state;
    80002804:	4c9c                	lw	a5,24(s1)
    switch (state)
    80002806:	fd5787e3          	beq	a5,s5,800027d4 <clockintr+0x48>
    8000280a:	01478a63          	beq	a5,s4,8000281e <clockintr+0x92>
    8000280e:	fd3798e3          	bne	a5,s3,800027de <clockintr+0x52>
      p->performance->stime += 1;
    80002812:	1684b703          	ld	a4,360(s1)
    80002816:	471c                	lw	a5,8(a4)
    80002818:	2785                	addiw	a5,a5,1
    8000281a:	c71c                	sw	a5,8(a4)
      break;
    8000281c:	b7c9                	j	800027de <clockintr+0x52>
      p->performance->runtime += 1;
    8000281e:	1684b703          	ld	a4,360(s1)
    80002822:	4b1c                	lw	a5,16(a4)
    80002824:	2785                	addiw	a5,a5,1
    80002826:	cb1c                	sw	a5,16(a4)
      break;
    80002828:	bf5d                	j	800027de <clockintr+0x52>
  }
  // end add
  wakeup(&ticks);
    8000282a:	00007517          	auipc	a0,0x7
    8000282e:	80650513          	addi	a0,a0,-2042 # 80009030 <ticks>
    80002832:	00000097          	auipc	ra,0x0
    80002836:	a06080e7          	jalr	-1530(ra) # 80002238 <wakeup>
  release(&tickslock);
    8000283a:	00015517          	auipc	a0,0x15
    8000283e:	a9650513          	addi	a0,a0,-1386 # 800172d0 <tickslock>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	434080e7          	jalr	1076(ra) # 80000c76 <release>
}
    8000284a:	70e2                	ld	ra,56(sp)
    8000284c:	7442                	ld	s0,48(sp)
    8000284e:	74a2                	ld	s1,40(sp)
    80002850:	7902                	ld	s2,32(sp)
    80002852:	69e2                	ld	s3,24(sp)
    80002854:	6a42                	ld	s4,16(sp)
    80002856:	6aa2                	ld	s5,8(sp)
    80002858:	6121                	addi	sp,sp,64
    8000285a:	8082                	ret

000000008000285c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000285c:	1101                	addi	sp,sp,-32
    8000285e:	ec06                	sd	ra,24(sp)
    80002860:	e822                	sd	s0,16(sp)
    80002862:	e426                	sd	s1,8(sp)
    80002864:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002866:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000286a:	00074d63          	bltz	a4,80002884 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000286e:	57fd                	li	a5,-1
    80002870:	17fe                	slli	a5,a5,0x3f
    80002872:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002874:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002876:	06f70363          	beq	a4,a5,800028dc <devintr+0x80>
  }
}
    8000287a:	60e2                	ld	ra,24(sp)
    8000287c:	6442                	ld	s0,16(sp)
    8000287e:	64a2                	ld	s1,8(sp)
    80002880:	6105                	addi	sp,sp,32
    80002882:	8082                	ret
     (scause & 0xff) == 9){
    80002884:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002888:	46a5                	li	a3,9
    8000288a:	fed792e3          	bne	a5,a3,8000286e <devintr+0x12>
    int irq = plic_claim();
    8000288e:	00003097          	auipc	ra,0x3
    80002892:	56a080e7          	jalr	1386(ra) # 80005df8 <plic_claim>
    80002896:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002898:	47a9                	li	a5,10
    8000289a:	02f50763          	beq	a0,a5,800028c8 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000289e:	4785                	li	a5,1
    800028a0:	02f50963          	beq	a0,a5,800028d2 <devintr+0x76>
    return 1;
    800028a4:	4505                	li	a0,1
    } else if(irq){
    800028a6:	d8f1                	beqz	s1,8000287a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028a8:	85a6                	mv	a1,s1
    800028aa:	00006517          	auipc	a0,0x6
    800028ae:	a3650513          	addi	a0,a0,-1482 # 800082e0 <states.0+0x38>
    800028b2:	ffffe097          	auipc	ra,0xffffe
    800028b6:	cc2080e7          	jalr	-830(ra) # 80000574 <printf>
      plic_complete(irq);
    800028ba:	8526                	mv	a0,s1
    800028bc:	00003097          	auipc	ra,0x3
    800028c0:	560080e7          	jalr	1376(ra) # 80005e1c <plic_complete>
    return 1;
    800028c4:	4505                	li	a0,1
    800028c6:	bf55                	j	8000287a <devintr+0x1e>
      uartintr();
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	0be080e7          	jalr	190(ra) # 80000986 <uartintr>
    800028d0:	b7ed                	j	800028ba <devintr+0x5e>
      virtio_disk_intr();
    800028d2:	00004097          	auipc	ra,0x4
    800028d6:	9dc080e7          	jalr	-1572(ra) # 800062ae <virtio_disk_intr>
    800028da:	b7c5                	j	800028ba <devintr+0x5e>
    if(cpuid() == 0){
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	08a080e7          	jalr	138(ra) # 80001966 <cpuid>
    800028e4:	c901                	beqz	a0,800028f4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028e6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028ea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ec:	14479073          	csrw	sip,a5
    return 2;
    800028f0:	4509                	li	a0,2
    800028f2:	b761                	j	8000287a <devintr+0x1e>
      clockintr();
    800028f4:	00000097          	auipc	ra,0x0
    800028f8:	e98080e7          	jalr	-360(ra) # 8000278c <clockintr>
    800028fc:	b7ed                	j	800028e6 <devintr+0x8a>

00000000800028fe <usertrap>:
{
    800028fe:	1101                	addi	sp,sp,-32
    80002900:	ec06                	sd	ra,24(sp)
    80002902:	e822                	sd	s0,16(sp)
    80002904:	e426                	sd	s1,8(sp)
    80002906:	e04a                	sd	s2,0(sp)
    80002908:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000290e:	1007f793          	andi	a5,a5,256
    80002912:	e3ad                	bnez	a5,80002974 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002914:	00003797          	auipc	a5,0x3
    80002918:	3dc78793          	addi	a5,a5,988 # 80005cf0 <kernelvec>
    8000291c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002920:	fffff097          	auipc	ra,0xfffff
    80002924:	072080e7          	jalr	114(ra) # 80001992 <myproc>
    80002928:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000292a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292c:	14102773          	csrr	a4,sepc
    80002930:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002932:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002936:	47a1                	li	a5,8
    80002938:	04f71c63          	bne	a4,a5,80002990 <usertrap+0x92>
    if(p->killed)
    8000293c:	551c                	lw	a5,40(a0)
    8000293e:	e3b9                	bnez	a5,80002984 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002940:	6cb8                	ld	a4,88(s1)
    80002942:	6f1c                	ld	a5,24(a4)
    80002944:	0791                	addi	a5,a5,4
    80002946:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002948:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000294c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002950:	10079073          	csrw	sstatus,a5
    syscall();
    80002954:	00000097          	auipc	ra,0x0
    80002958:	2e0080e7          	jalr	736(ra) # 80002c34 <syscall>
  if(p->killed)
    8000295c:	549c                	lw	a5,40(s1)
    8000295e:	ebc1                	bnez	a5,800029ee <usertrap+0xf0>
  usertrapret();
    80002960:	00000097          	auipc	ra,0x0
    80002964:	d8e080e7          	jalr	-626(ra) # 800026ee <usertrapret>
}
    80002968:	60e2                	ld	ra,24(sp)
    8000296a:	6442                	ld	s0,16(sp)
    8000296c:	64a2                	ld	s1,8(sp)
    8000296e:	6902                	ld	s2,0(sp)
    80002970:	6105                	addi	sp,sp,32
    80002972:	8082                	ret
    panic("usertrap: not from user mode");
    80002974:	00006517          	auipc	a0,0x6
    80002978:	98c50513          	addi	a0,a0,-1652 # 80008300 <states.0+0x58>
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	bae080e7          	jalr	-1106(ra) # 8000052a <panic>
      exit(-1);
    80002984:	557d                	li	a0,-1
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	982080e7          	jalr	-1662(ra) # 80002308 <exit>
    8000298e:	bf4d                	j	80002940 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002990:	00000097          	auipc	ra,0x0
    80002994:	ecc080e7          	jalr	-308(ra) # 8000285c <devintr>
    80002998:	892a                	mv	s2,a0
    8000299a:	c501                	beqz	a0,800029a2 <usertrap+0xa4>
  if(p->killed)
    8000299c:	549c                	lw	a5,40(s1)
    8000299e:	c3a1                	beqz	a5,800029de <usertrap+0xe0>
    800029a0:	a815                	j	800029d4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a2:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029a6:	5890                	lw	a2,48(s1)
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	97850513          	addi	a0,a0,-1672 # 80008320 <states.0+0x78>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	bc4080e7          	jalr	-1084(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029bc:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	99050513          	addi	a0,a0,-1648 # 80008350 <states.0+0xa8>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	bac080e7          	jalr	-1108(ra) # 80000574 <printf>
    p->killed = 1;
    800029d0:	4785                	li	a5,1
    800029d2:	d49c                	sw	a5,40(s1)
    exit(-1);
    800029d4:	557d                	li	a0,-1
    800029d6:	00000097          	auipc	ra,0x0
    800029da:	932080e7          	jalr	-1742(ra) # 80002308 <exit>
  if(which_dev == 2)
    800029de:	4789                	li	a5,2
    800029e0:	f8f910e3          	bne	s2,a5,80002960 <usertrap+0x62>
    yield();
    800029e4:	fffff097          	auipc	ra,0xfffff
    800029e8:	68c080e7          	jalr	1676(ra) # 80002070 <yield>
    800029ec:	bf95                	j	80002960 <usertrap+0x62>
  int which_dev = 0;
    800029ee:	4901                	li	s2,0
    800029f0:	b7d5                	j	800029d4 <usertrap+0xd6>

00000000800029f2 <kerneltrap>:
{
    800029f2:	7179                	addi	sp,sp,-48
    800029f4:	f406                	sd	ra,40(sp)
    800029f6:	f022                	sd	s0,32(sp)
    800029f8:	ec26                	sd	s1,24(sp)
    800029fa:	e84a                	sd	s2,16(sp)
    800029fc:	e44e                	sd	s3,8(sp)
    800029fe:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a00:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a08:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a0c:	1004f793          	andi	a5,s1,256
    80002a10:	cb85                	beqz	a5,80002a40 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a12:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a16:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a18:	ef85                	bnez	a5,80002a50 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a1a:	00000097          	auipc	ra,0x0
    80002a1e:	e42080e7          	jalr	-446(ra) # 8000285c <devintr>
    80002a22:	cd1d                	beqz	a0,80002a60 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a24:	4789                	li	a5,2
    80002a26:	06f50a63          	beq	a0,a5,80002a9a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a2e:	10049073          	csrw	sstatus,s1
}
    80002a32:	70a2                	ld	ra,40(sp)
    80002a34:	7402                	ld	s0,32(sp)
    80002a36:	64e2                	ld	s1,24(sp)
    80002a38:	6942                	ld	s2,16(sp)
    80002a3a:	69a2                	ld	s3,8(sp)
    80002a3c:	6145                	addi	sp,sp,48
    80002a3e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	93050513          	addi	a0,a0,-1744 # 80008370 <states.0+0xc8>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	ae2080e7          	jalr	-1310(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	94850513          	addi	a0,a0,-1720 # 80008398 <states.0+0xf0>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	ad2080e7          	jalr	-1326(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002a60:	85ce                	mv	a1,s3
    80002a62:	00006517          	auipc	a0,0x6
    80002a66:	95650513          	addi	a0,a0,-1706 # 800083b8 <states.0+0x110>
    80002a6a:	ffffe097          	auipc	ra,0xffffe
    80002a6e:	b0a080e7          	jalr	-1270(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a72:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a76:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	94e50513          	addi	a0,a0,-1714 # 800083c8 <states.0+0x120>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	af2080e7          	jalr	-1294(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002a8a:	00006517          	auipc	a0,0x6
    80002a8e:	95650513          	addi	a0,a0,-1706 # 800083e0 <states.0+0x138>
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	a98080e7          	jalr	-1384(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a9a:	fffff097          	auipc	ra,0xfffff
    80002a9e:	ef8080e7          	jalr	-264(ra) # 80001992 <myproc>
    80002aa2:	d541                	beqz	a0,80002a2a <kerneltrap+0x38>
    80002aa4:	fffff097          	auipc	ra,0xfffff
    80002aa8:	eee080e7          	jalr	-274(ra) # 80001992 <myproc>
    80002aac:	4d18                	lw	a4,24(a0)
    80002aae:	4791                	li	a5,4
    80002ab0:	f6f71de3          	bne	a4,a5,80002a2a <kerneltrap+0x38>
    yield();
    80002ab4:	fffff097          	auipc	ra,0xfffff
    80002ab8:	5bc080e7          	jalr	1468(ra) # 80002070 <yield>
    80002abc:	b7bd                	j	80002a2a <kerneltrap+0x38>

0000000080002abe <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002abe:	1101                	addi	sp,sp,-32
    80002ac0:	ec06                	sd	ra,24(sp)
    80002ac2:	e822                	sd	s0,16(sp)
    80002ac4:	e426                	sd	s1,8(sp)
    80002ac6:	1000                	addi	s0,sp,32
    80002ac8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	ec8080e7          	jalr	-312(ra) # 80001992 <myproc>
  switch (n)
    80002ad2:	4795                	li	a5,5
    80002ad4:	0497e163          	bltu	a5,s1,80002b16 <argraw+0x58>
    80002ad8:	048a                	slli	s1,s1,0x2
    80002ada:	00006717          	auipc	a4,0x6
    80002ade:	abe70713          	addi	a4,a4,-1346 # 80008598 <states.0+0x2f0>
    80002ae2:	94ba                	add	s1,s1,a4
    80002ae4:	409c                	lw	a5,0(s1)
    80002ae6:	97ba                	add	a5,a5,a4
    80002ae8:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002aea:	6d3c                	ld	a5,88(a0)
    80002aec:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aee:	60e2                	ld	ra,24(sp)
    80002af0:	6442                	ld	s0,16(sp)
    80002af2:	64a2                	ld	s1,8(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret
    return p->trapframe->a1;
    80002af8:	6d3c                	ld	a5,88(a0)
    80002afa:	7fa8                	ld	a0,120(a5)
    80002afc:	bfcd                	j	80002aee <argraw+0x30>
    return p->trapframe->a2;
    80002afe:	6d3c                	ld	a5,88(a0)
    80002b00:	63c8                	ld	a0,128(a5)
    80002b02:	b7f5                	j	80002aee <argraw+0x30>
    return p->trapframe->a3;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	67c8                	ld	a0,136(a5)
    80002b08:	b7dd                	j	80002aee <argraw+0x30>
    return p->trapframe->a4;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	6bc8                	ld	a0,144(a5)
    80002b0e:	b7c5                	j	80002aee <argraw+0x30>
    return p->trapframe->a5;
    80002b10:	6d3c                	ld	a5,88(a0)
    80002b12:	6fc8                	ld	a0,152(a5)
    80002b14:	bfe9                	j	80002aee <argraw+0x30>
  panic("argraw");
    80002b16:	00006517          	auipc	a0,0x6
    80002b1a:	8da50513          	addi	a0,a0,-1830 # 800083f0 <states.0+0x148>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a0c080e7          	jalr	-1524(ra) # 8000052a <panic>

0000000080002b26 <fetchaddr>:
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	e04a                	sd	s2,0(sp)
    80002b30:	1000                	addi	s0,sp,32
    80002b32:	84aa                	mv	s1,a0
    80002b34:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	e5c080e7          	jalr	-420(ra) # 80001992 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002b3e:	653c                	ld	a5,72(a0)
    80002b40:	02f4f863          	bgeu	s1,a5,80002b70 <fetchaddr+0x4a>
    80002b44:	00848713          	addi	a4,s1,8
    80002b48:	02e7e663          	bltu	a5,a4,80002b74 <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b4c:	46a1                	li	a3,8
    80002b4e:	8626                	mv	a2,s1
    80002b50:	85ca                	mv	a1,s2
    80002b52:	6928                	ld	a0,80(a0)
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	b76080e7          	jalr	-1162(ra) # 800016ca <copyin>
    80002b5c:	00a03533          	snez	a0,a0
    80002b60:	40a00533          	neg	a0,a0
}
    80002b64:	60e2                	ld	ra,24(sp)
    80002b66:	6442                	ld	s0,16(sp)
    80002b68:	64a2                	ld	s1,8(sp)
    80002b6a:	6902                	ld	s2,0(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret
    return -1;
    80002b70:	557d                	li	a0,-1
    80002b72:	bfcd                	j	80002b64 <fetchaddr+0x3e>
    80002b74:	557d                	li	a0,-1
    80002b76:	b7fd                	j	80002b64 <fetchaddr+0x3e>

0000000080002b78 <fetchstr>:
{
    80002b78:	7179                	addi	sp,sp,-48
    80002b7a:	f406                	sd	ra,40(sp)
    80002b7c:	f022                	sd	s0,32(sp)
    80002b7e:	ec26                	sd	s1,24(sp)
    80002b80:	e84a                	sd	s2,16(sp)
    80002b82:	e44e                	sd	s3,8(sp)
    80002b84:	1800                	addi	s0,sp,48
    80002b86:	892a                	mv	s2,a0
    80002b88:	84ae                	mv	s1,a1
    80002b8a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e06080e7          	jalr	-506(ra) # 80001992 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b94:	86ce                	mv	a3,s3
    80002b96:	864a                	mv	a2,s2
    80002b98:	85a6                	mv	a1,s1
    80002b9a:	6928                	ld	a0,80(a0)
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	bbc080e7          	jalr	-1092(ra) # 80001758 <copyinstr>
  if (err < 0)
    80002ba4:	00054763          	bltz	a0,80002bb2 <fetchstr+0x3a>
  return strlen(buf);
    80002ba8:	8526                	mv	a0,s1
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	298080e7          	jalr	664(ra) # 80000e42 <strlen>
}
    80002bb2:	70a2                	ld	ra,40(sp)
    80002bb4:	7402                	ld	s0,32(sp)
    80002bb6:	64e2                	ld	s1,24(sp)
    80002bb8:	6942                	ld	s2,16(sp)
    80002bba:	69a2                	ld	s3,8(sp)
    80002bbc:	6145                	addi	sp,sp,48
    80002bbe:	8082                	ret

0000000080002bc0 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002bc0:	1101                	addi	sp,sp,-32
    80002bc2:	ec06                	sd	ra,24(sp)
    80002bc4:	e822                	sd	s0,16(sp)
    80002bc6:	e426                	sd	s1,8(sp)
    80002bc8:	1000                	addi	s0,sp,32
    80002bca:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	ef2080e7          	jalr	-270(ra) # 80002abe <argraw>
    80002bd4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bd6:	4501                	li	a0,0
    80002bd8:	60e2                	ld	ra,24(sp)
    80002bda:	6442                	ld	s0,16(sp)
    80002bdc:	64a2                	ld	s1,8(sp)
    80002bde:	6105                	addi	sp,sp,32
    80002be0:	8082                	ret

0000000080002be2 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	1000                	addi	s0,sp,32
    80002bec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	ed0080e7          	jalr	-304(ra) # 80002abe <argraw>
    80002bf6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bf8:	4501                	li	a0,0
    80002bfa:	60e2                	ld	ra,24(sp)
    80002bfc:	6442                	ld	s0,16(sp)
    80002bfe:	64a2                	ld	s1,8(sp)
    80002c00:	6105                	addi	sp,sp,32
    80002c02:	8082                	ret

0000000080002c04 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002c04:	1101                	addi	sp,sp,-32
    80002c06:	ec06                	sd	ra,24(sp)
    80002c08:	e822                	sd	s0,16(sp)
    80002c0a:	e426                	sd	s1,8(sp)
    80002c0c:	e04a                	sd	s2,0(sp)
    80002c0e:	1000                	addi	s0,sp,32
    80002c10:	84ae                	mv	s1,a1
    80002c12:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c14:	00000097          	auipc	ra,0x0
    80002c18:	eaa080e7          	jalr	-342(ra) # 80002abe <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c1c:	864a                	mv	a2,s2
    80002c1e:	85a6                	mv	a1,s1
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	f58080e7          	jalr	-168(ra) # 80002b78 <fetchstr>
}
    80002c28:	60e2                	ld	ra,24(sp)
    80002c2a:	6442                	ld	s0,16(sp)
    80002c2c:	64a2                	ld	s1,8(sp)
    80002c2e:	6902                	ld	s2,0(sp)
    80002c30:	6105                	addi	sp,sp,32
    80002c32:	8082                	ret

0000000080002c34 <syscall>:
    [SYS_mkdir] "sys_mkdir",
    [SYS_close] "sys_close",
    [SYS_trace] "sys_trace",
};
void syscall(void)
{
    80002c34:	7139                	addi	sp,sp,-64
    80002c36:	fc06                	sd	ra,56(sp)
    80002c38:	f822                	sd	s0,48(sp)
    80002c3a:	f426                	sd	s1,40(sp)
    80002c3c:	f04a                	sd	s2,32(sp)
    80002c3e:	ec4e                	sd	s3,24(sp)
    80002c40:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	d50080e7          	jalr	-688(ra) # 80001992 <myproc>
    80002c4a:	84aa                	mv	s1,a0
  int firstArg;
  num = p->trapframe->a7;
    80002c4c:	05853903          	ld	s2,88(a0)
    80002c50:	0a893783          	ld	a5,168(s2)
    80002c54:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002c58:	37fd                	addiw	a5,a5,-1
    80002c5a:	4755                	li	a4,21
    80002c5c:	0cf76563          	bltu	a4,a5,80002d26 <syscall+0xf2>
    80002c60:	00399713          	slli	a4,s3,0x3
    80002c64:	00006797          	auipc	a5,0x6
    80002c68:	94c78793          	addi	a5,a5,-1716 # 800085b0 <syscalls>
    80002c6c:	97ba                	add	a5,a5,a4
    80002c6e:	639c                	ld	a5,0(a5)
    80002c70:	cbdd                	beqz	a5,80002d26 <syscall+0xf2>
  {
    p->trapframe->a0 = syscalls[num]();
    80002c72:	9782                	jalr	a5
    80002c74:	06a93823          	sd	a0,112(s2)
    //start messing with code
    if ((p->traceMask & (1 << num)))
    80002c78:	58dc                	lw	a5,52(s1)
    80002c7a:	4137d7bb          	sraw	a5,a5,s3
    80002c7e:	8b85                	andi	a5,a5,1
    80002c80:	c3f1                	beqz	a5,80002d44 <syscall+0x110>
    {
      printf("%d: syscall %s ", p->pid, syscalls_str[num]);
    80002c82:	00399713          	slli	a4,s3,0x3
    80002c86:	00006797          	auipc	a5,0x6
    80002c8a:	92a78793          	addi	a5,a5,-1750 # 800085b0 <syscalls>
    80002c8e:	97ba                	add	a5,a5,a4
    80002c90:	7fd0                	ld	a2,184(a5)
    80002c92:	588c                	lw	a1,48(s1)
    80002c94:	00005517          	auipc	a0,0x5
    80002c98:	76450513          	addi	a0,a0,1892 # 800083f8 <states.0+0x150>
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	8d8080e7          	jalr	-1832(ra) # 80000574 <printf>
      if (num == SYS_fork)
    80002ca4:	4785                	li	a5,1
    80002ca6:	02f98363          	beq	s3,a5,80002ccc <syscall+0x98>
      {
        printf("NULL ");
      }
      if (num == SYS_kill)
    80002caa:	4799                	li	a5,6
    80002cac:	02f98963          	beq	s3,a5,80002cde <syscall+0xaa>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      if (num == SYS_sbrk)
    80002cb0:	47b1                	li	a5,12
    80002cb2:	04f98863          	beq	s3,a5,80002d02 <syscall+0xce>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002cb6:	6cbc                	ld	a5,88(s1)
    80002cb8:	7bac                	ld	a1,112(a5)
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	75e50513          	addi	a0,a0,1886 # 80008418 <states.0+0x170>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8b2080e7          	jalr	-1870(ra) # 80000574 <printf>
    80002cca:	a8ad                	j	80002d44 <syscall+0x110>
        printf("NULL ");
    80002ccc:	00005517          	auipc	a0,0x5
    80002cd0:	73c50513          	addi	a0,a0,1852 # 80008408 <states.0+0x160>
    80002cd4:	ffffe097          	auipc	ra,0xffffe
    80002cd8:	8a0080e7          	jalr	-1888(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002cdc:	bfe9                	j	80002cb6 <syscall+0x82>
        argint(0, &firstArg);
    80002cde:	fcc40593          	addi	a1,s0,-52
    80002ce2:	4501                	li	a0,0
    80002ce4:	00000097          	auipc	ra,0x0
    80002ce8:	edc080e7          	jalr	-292(ra) # 80002bc0 <argint>
        printf("%d ", firstArg);
    80002cec:	fcc42583          	lw	a1,-52(s0)
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	72050513          	addi	a0,a0,1824 # 80008410 <states.0+0x168>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	87c080e7          	jalr	-1924(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002d00:	bf5d                	j	80002cb6 <syscall+0x82>
        argint(0, &firstArg);
    80002d02:	fcc40593          	addi	a1,s0,-52
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	eb8080e7          	jalr	-328(ra) # 80002bc0 <argint>
        printf("%d ", firstArg);
    80002d10:	fcc42583          	lw	a1,-52(s0)
    80002d14:	00005517          	auipc	a0,0x5
    80002d18:	6fc50513          	addi	a0,a0,1788 # 80008410 <states.0+0x168>
    80002d1c:	ffffe097          	auipc	ra,0xffffe
    80002d20:	858080e7          	jalr	-1960(ra) # 80000574 <printf>
    80002d24:	bf49                	j	80002cb6 <syscall+0x82>
    }
    //end messing with code
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002d26:	86ce                	mv	a3,s3
    80002d28:	15848613          	addi	a2,s1,344
    80002d2c:	588c                	lw	a1,48(s1)
    80002d2e:	00005517          	auipc	a0,0x5
    80002d32:	6f250513          	addi	a0,a0,1778 # 80008420 <states.0+0x178>
    80002d36:	ffffe097          	auipc	ra,0xffffe
    80002d3a:	83e080e7          	jalr	-1986(ra) # 80000574 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d3e:	6cbc                	ld	a5,88(s1)
    80002d40:	577d                	li	a4,-1
    80002d42:	fbb8                	sd	a4,112(a5)
  }
}
    80002d44:	70e2                	ld	ra,56(sp)
    80002d46:	7442                	ld	s0,48(sp)
    80002d48:	74a2                	ld	s1,40(sp)
    80002d4a:	7902                	ld	s2,32(sp)
    80002d4c:	69e2                	ld	s3,24(sp)
    80002d4e:	6121                	addi	sp,sp,64
    80002d50:	8082                	ret

0000000080002d52 <sys_trace>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_trace(void)
{
    80002d52:	1101                	addi	sp,sp,-32
    80002d54:	ec06                	sd	ra,24(sp)
    80002d56:	e822                	sd	s0,16(sp)
    80002d58:	1000                	addi	s0,sp,32
  int mask;
  int pid;
  argint(0, &mask);
    80002d5a:	fec40593          	addi	a1,s0,-20
    80002d5e:	4501                	li	a0,0
    80002d60:	00000097          	auipc	ra,0x0
    80002d64:	e60080e7          	jalr	-416(ra) # 80002bc0 <argint>
  if(argint(1, &pid) < 0)
    80002d68:	fe840593          	addi	a1,s0,-24
    80002d6c:	4505                	li	a0,1
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	e52080e7          	jalr	-430(ra) # 80002bc0 <argint>
    80002d76:	87aa                	mv	a5,a0
    return -1;
    80002d78:	557d                	li	a0,-1
  if(argint(1, &pid) < 0)
    80002d7a:	0007ca63          	bltz	a5,80002d8e <sys_trace+0x3c>
  return trace(mask, pid);
    80002d7e:	fe842583          	lw	a1,-24(s0)
    80002d82:	fec42503          	lw	a0,-20(s0)
    80002d86:	fffff097          	auipc	ra,0xfffff
    80002d8a:	6f8080e7          	jalr	1784(ra) # 8000247e <trace>
}
    80002d8e:	60e2                	ld	ra,24(sp)
    80002d90:	6442                	ld	s0,16(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret

0000000080002d96 <sys_exit>:

uint64
sys_exit(void)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d9e:	fec40593          	addi	a1,s0,-20
    80002da2:	4501                	li	a0,0
    80002da4:	00000097          	auipc	ra,0x0
    80002da8:	e1c080e7          	jalr	-484(ra) # 80002bc0 <argint>
    return -1;
    80002dac:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dae:	00054963          	bltz	a0,80002dc0 <sys_exit+0x2a>
  exit(n);
    80002db2:	fec42503          	lw	a0,-20(s0)
    80002db6:	fffff097          	auipc	ra,0xfffff
    80002dba:	552080e7          	jalr	1362(ra) # 80002308 <exit>
  return 0;  // not reached
    80002dbe:	4781                	li	a5,0
}
    80002dc0:	853e                	mv	a0,a5
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dca:	1141                	addi	sp,sp,-16
    80002dcc:	e406                	sd	ra,8(sp)
    80002dce:	e022                	sd	s0,0(sp)
    80002dd0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	bc0080e7          	jalr	-1088(ra) # 80001992 <myproc>
}
    80002dda:	5908                	lw	a0,48(a0)
    80002ddc:	60a2                	ld	ra,8(sp)
    80002dde:	6402                	ld	s0,0(sp)
    80002de0:	0141                	addi	sp,sp,16
    80002de2:	8082                	ret

0000000080002de4 <sys_fork>:

uint64
sys_fork(void)
{
    80002de4:	1141                	addi	sp,sp,-16
    80002de6:	e406                	sd	ra,8(sp)
    80002de8:	e022                	sd	s0,0(sp)
    80002dea:	0800                	addi	s0,sp,16
  return fork();
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	fc6080e7          	jalr	-58(ra) # 80001db2 <fork>
}
    80002df4:	60a2                	ld	ra,8(sp)
    80002df6:	6402                	ld	s0,0(sp)
    80002df8:	0141                	addi	sp,sp,16
    80002dfa:	8082                	ret

0000000080002dfc <sys_wait>:

uint64
sys_wait(void)
{
    80002dfc:	1101                	addi	sp,sp,-32
    80002dfe:	ec06                	sd	ra,24(sp)
    80002e00:	e822                	sd	s0,16(sp)
    80002e02:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002e04:	fe840593          	addi	a1,s0,-24
    80002e08:	4501                	li	a0,0
    80002e0a:	00000097          	auipc	ra,0x0
    80002e0e:	dd8080e7          	jalr	-552(ra) # 80002be2 <argaddr>
    80002e12:	87aa                	mv	a5,a0
    return -1;
    80002e14:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e16:	0007c863          	bltz	a5,80002e26 <sys_wait+0x2a>
  return wait(p);
    80002e1a:	fe843503          	ld	a0,-24(s0)
    80002e1e:	fffff097          	auipc	ra,0xfffff
    80002e22:	2f2080e7          	jalr	754(ra) # 80002110 <wait>
}
    80002e26:	60e2                	ld	ra,24(sp)
    80002e28:	6442                	ld	s0,16(sp)
    80002e2a:	6105                	addi	sp,sp,32
    80002e2c:	8082                	ret

0000000080002e2e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e2e:	7179                	addi	sp,sp,-48
    80002e30:	f406                	sd	ra,40(sp)
    80002e32:	f022                	sd	s0,32(sp)
    80002e34:	ec26                	sd	s1,24(sp)
    80002e36:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e38:	fdc40593          	addi	a1,s0,-36
    80002e3c:	4501                	li	a0,0
    80002e3e:	00000097          	auipc	ra,0x0
    80002e42:	d82080e7          	jalr	-638(ra) # 80002bc0 <argint>
    return -1;
    80002e46:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002e48:	00054f63          	bltz	a0,80002e66 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	b46080e7          	jalr	-1210(ra) # 80001992 <myproc>
    80002e54:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e56:	fdc42503          	lw	a0,-36(s0)
    80002e5a:	fffff097          	auipc	ra,0xfffff
    80002e5e:	ee4080e7          	jalr	-284(ra) # 80001d3e <growproc>
    80002e62:	00054863          	bltz	a0,80002e72 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e66:	8526                	mv	a0,s1
    80002e68:	70a2                	ld	ra,40(sp)
    80002e6a:	7402                	ld	s0,32(sp)
    80002e6c:	64e2                	ld	s1,24(sp)
    80002e6e:	6145                	addi	sp,sp,48
    80002e70:	8082                	ret
    return -1;
    80002e72:	54fd                	li	s1,-1
    80002e74:	bfcd                	j	80002e66 <sys_sbrk+0x38>

0000000080002e76 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e76:	7139                	addi	sp,sp,-64
    80002e78:	fc06                	sd	ra,56(sp)
    80002e7a:	f822                	sd	s0,48(sp)
    80002e7c:	f426                	sd	s1,40(sp)
    80002e7e:	f04a                	sd	s2,32(sp)
    80002e80:	ec4e                	sd	s3,24(sp)
    80002e82:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e84:	fcc40593          	addi	a1,s0,-52
    80002e88:	4501                	li	a0,0
    80002e8a:	00000097          	auipc	ra,0x0
    80002e8e:	d36080e7          	jalr	-714(ra) # 80002bc0 <argint>
    return -1;
    80002e92:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e94:	06054563          	bltz	a0,80002efe <sys_sleep+0x88>
  acquire(&tickslock);
    80002e98:	00014517          	auipc	a0,0x14
    80002e9c:	43850513          	addi	a0,a0,1080 # 800172d0 <tickslock>
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	d22080e7          	jalr	-734(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    80002ea8:	00006917          	auipc	s2,0x6
    80002eac:	18892903          	lw	s2,392(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002eb0:	fcc42783          	lw	a5,-52(s0)
    80002eb4:	cf85                	beqz	a5,80002eec <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eb6:	00014997          	auipc	s3,0x14
    80002eba:	41a98993          	addi	s3,s3,1050 # 800172d0 <tickslock>
    80002ebe:	00006497          	auipc	s1,0x6
    80002ec2:	17248493          	addi	s1,s1,370 # 80009030 <ticks>
    if(myproc()->killed){
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	acc080e7          	jalr	-1332(ra) # 80001992 <myproc>
    80002ece:	551c                	lw	a5,40(a0)
    80002ed0:	ef9d                	bnez	a5,80002f0e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ed2:	85ce                	mv	a1,s3
    80002ed4:	8526                	mv	a0,s1
    80002ed6:	fffff097          	auipc	ra,0xfffff
    80002eda:	1d6080e7          	jalr	470(ra) # 800020ac <sleep>
  while(ticks - ticks0 < n){
    80002ede:	409c                	lw	a5,0(s1)
    80002ee0:	412787bb          	subw	a5,a5,s2
    80002ee4:	fcc42703          	lw	a4,-52(s0)
    80002ee8:	fce7efe3          	bltu	a5,a4,80002ec6 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002eec:	00014517          	auipc	a0,0x14
    80002ef0:	3e450513          	addi	a0,a0,996 # 800172d0 <tickslock>
    80002ef4:	ffffe097          	auipc	ra,0xffffe
    80002ef8:	d82080e7          	jalr	-638(ra) # 80000c76 <release>
  return 0;
    80002efc:	4781                	li	a5,0
}
    80002efe:	853e                	mv	a0,a5
    80002f00:	70e2                	ld	ra,56(sp)
    80002f02:	7442                	ld	s0,48(sp)
    80002f04:	74a2                	ld	s1,40(sp)
    80002f06:	7902                	ld	s2,32(sp)
    80002f08:	69e2                	ld	s3,24(sp)
    80002f0a:	6121                	addi	sp,sp,64
    80002f0c:	8082                	ret
      release(&tickslock);
    80002f0e:	00014517          	auipc	a0,0x14
    80002f12:	3c250513          	addi	a0,a0,962 # 800172d0 <tickslock>
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	d60080e7          	jalr	-672(ra) # 80000c76 <release>
      return -1;
    80002f1e:	57fd                	li	a5,-1
    80002f20:	bff9                	j	80002efe <sys_sleep+0x88>

0000000080002f22 <sys_kill>:

uint64
sys_kill(void)
{
    80002f22:	1101                	addi	sp,sp,-32
    80002f24:	ec06                	sd	ra,24(sp)
    80002f26:	e822                	sd	s0,16(sp)
    80002f28:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f2a:	fec40593          	addi	a1,s0,-20
    80002f2e:	4501                	li	a0,0
    80002f30:	00000097          	auipc	ra,0x0
    80002f34:	c90080e7          	jalr	-880(ra) # 80002bc0 <argint>
    80002f38:	87aa                	mv	a5,a0
    return -1;
    80002f3a:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f3c:	0007c863          	bltz	a5,80002f4c <sys_kill+0x2a>
  return kill(pid);
    80002f40:	fec42503          	lw	a0,-20(s0)
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	4c8080e7          	jalr	1224(ra) # 8000240c <kill>
}
    80002f4c:	60e2                	ld	ra,24(sp)
    80002f4e:	6442                	ld	s0,16(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret

0000000080002f54 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f54:	1101                	addi	sp,sp,-32
    80002f56:	ec06                	sd	ra,24(sp)
    80002f58:	e822                	sd	s0,16(sp)
    80002f5a:	e426                	sd	s1,8(sp)
    80002f5c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f5e:	00014517          	auipc	a0,0x14
    80002f62:	37250513          	addi	a0,a0,882 # 800172d0 <tickslock>
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	c5c080e7          	jalr	-932(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80002f6e:	00006497          	auipc	s1,0x6
    80002f72:	0c24a483          	lw	s1,194(s1) # 80009030 <ticks>
  release(&tickslock);
    80002f76:	00014517          	auipc	a0,0x14
    80002f7a:	35a50513          	addi	a0,a0,858 # 800172d0 <tickslock>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	cf8080e7          	jalr	-776(ra) # 80000c76 <release>
  return xticks;
}
    80002f86:	02049513          	slli	a0,s1,0x20
    80002f8a:	9101                	srli	a0,a0,0x20
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	64a2                	ld	s1,8(sp)
    80002f92:	6105                	addi	sp,sp,32
    80002f94:	8082                	ret

0000000080002f96 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f96:	7179                	addi	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	e44e                	sd	s3,8(sp)
    80002fa2:	e052                	sd	s4,0(sp)
    80002fa4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fa6:	00005597          	auipc	a1,0x5
    80002faa:	77a58593          	addi	a1,a1,1914 # 80008720 <syscalls_str+0xb8>
    80002fae:	00014517          	auipc	a0,0x14
    80002fb2:	33a50513          	addi	a0,a0,826 # 800172e8 <bcache>
    80002fb6:	ffffe097          	auipc	ra,0xffffe
    80002fba:	b7c080e7          	jalr	-1156(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fbe:	0001c797          	auipc	a5,0x1c
    80002fc2:	32a78793          	addi	a5,a5,810 # 8001f2e8 <bcache+0x8000>
    80002fc6:	0001c717          	auipc	a4,0x1c
    80002fca:	58a70713          	addi	a4,a4,1418 # 8001f550 <bcache+0x8268>
    80002fce:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fd2:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fd6:	00014497          	auipc	s1,0x14
    80002fda:	32a48493          	addi	s1,s1,810 # 80017300 <bcache+0x18>
    b->next = bcache.head.next;
    80002fde:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fe0:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fe2:	00005a17          	auipc	s4,0x5
    80002fe6:	746a0a13          	addi	s4,s4,1862 # 80008728 <syscalls_str+0xc0>
    b->next = bcache.head.next;
    80002fea:	2b893783          	ld	a5,696(s2)
    80002fee:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002ff0:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ff4:	85d2                	mv	a1,s4
    80002ff6:	01048513          	addi	a0,s1,16
    80002ffa:	00001097          	auipc	ra,0x1
    80002ffe:	4c2080e7          	jalr	1218(ra) # 800044bc <initsleeplock>
    bcache.head.next->prev = b;
    80003002:	2b893783          	ld	a5,696(s2)
    80003006:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003008:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000300c:	45848493          	addi	s1,s1,1112
    80003010:	fd349de3          	bne	s1,s3,80002fea <binit+0x54>
  }
}
    80003014:	70a2                	ld	ra,40(sp)
    80003016:	7402                	ld	s0,32(sp)
    80003018:	64e2                	ld	s1,24(sp)
    8000301a:	6942                	ld	s2,16(sp)
    8000301c:	69a2                	ld	s3,8(sp)
    8000301e:	6a02                	ld	s4,0(sp)
    80003020:	6145                	addi	sp,sp,48
    80003022:	8082                	ret

0000000080003024 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003024:	7179                	addi	sp,sp,-48
    80003026:	f406                	sd	ra,40(sp)
    80003028:	f022                	sd	s0,32(sp)
    8000302a:	ec26                	sd	s1,24(sp)
    8000302c:	e84a                	sd	s2,16(sp)
    8000302e:	e44e                	sd	s3,8(sp)
    80003030:	1800                	addi	s0,sp,48
    80003032:	892a                	mv	s2,a0
    80003034:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003036:	00014517          	auipc	a0,0x14
    8000303a:	2b250513          	addi	a0,a0,690 # 800172e8 <bcache>
    8000303e:	ffffe097          	auipc	ra,0xffffe
    80003042:	b84080e7          	jalr	-1148(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003046:	0001c497          	auipc	s1,0x1c
    8000304a:	55a4b483          	ld	s1,1370(s1) # 8001f5a0 <bcache+0x82b8>
    8000304e:	0001c797          	auipc	a5,0x1c
    80003052:	50278793          	addi	a5,a5,1282 # 8001f550 <bcache+0x8268>
    80003056:	02f48f63          	beq	s1,a5,80003094 <bread+0x70>
    8000305a:	873e                	mv	a4,a5
    8000305c:	a021                	j	80003064 <bread+0x40>
    8000305e:	68a4                	ld	s1,80(s1)
    80003060:	02e48a63          	beq	s1,a4,80003094 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003064:	449c                	lw	a5,8(s1)
    80003066:	ff279ce3          	bne	a5,s2,8000305e <bread+0x3a>
    8000306a:	44dc                	lw	a5,12(s1)
    8000306c:	ff3799e3          	bne	a5,s3,8000305e <bread+0x3a>
      b->refcnt++;
    80003070:	40bc                	lw	a5,64(s1)
    80003072:	2785                	addiw	a5,a5,1
    80003074:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003076:	00014517          	auipc	a0,0x14
    8000307a:	27250513          	addi	a0,a0,626 # 800172e8 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	bf8080e7          	jalr	-1032(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    80003086:	01048513          	addi	a0,s1,16
    8000308a:	00001097          	auipc	ra,0x1
    8000308e:	46c080e7          	jalr	1132(ra) # 800044f6 <acquiresleep>
      return b;
    80003092:	a8b9                	j	800030f0 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003094:	0001c497          	auipc	s1,0x1c
    80003098:	5044b483          	ld	s1,1284(s1) # 8001f598 <bcache+0x82b0>
    8000309c:	0001c797          	auipc	a5,0x1c
    800030a0:	4b478793          	addi	a5,a5,1204 # 8001f550 <bcache+0x8268>
    800030a4:	00f48863          	beq	s1,a5,800030b4 <bread+0x90>
    800030a8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030aa:	40bc                	lw	a5,64(s1)
    800030ac:	cf81                	beqz	a5,800030c4 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ae:	64a4                	ld	s1,72(s1)
    800030b0:	fee49de3          	bne	s1,a4,800030aa <bread+0x86>
  panic("bget: no buffers");
    800030b4:	00005517          	auipc	a0,0x5
    800030b8:	67c50513          	addi	a0,a0,1660 # 80008730 <syscalls_str+0xc8>
    800030bc:	ffffd097          	auipc	ra,0xffffd
    800030c0:	46e080e7          	jalr	1134(ra) # 8000052a <panic>
      b->dev = dev;
    800030c4:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800030c8:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800030cc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030d0:	4785                	li	a5,1
    800030d2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d4:	00014517          	auipc	a0,0x14
    800030d8:	21450513          	addi	a0,a0,532 # 800172e8 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	b9a080e7          	jalr	-1126(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800030e4:	01048513          	addi	a0,s1,16
    800030e8:	00001097          	auipc	ra,0x1
    800030ec:	40e080e7          	jalr	1038(ra) # 800044f6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030f0:	409c                	lw	a5,0(s1)
    800030f2:	cb89                	beqz	a5,80003104 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030f4:	8526                	mv	a0,s1
    800030f6:	70a2                	ld	ra,40(sp)
    800030f8:	7402                	ld	s0,32(sp)
    800030fa:	64e2                	ld	s1,24(sp)
    800030fc:	6942                	ld	s2,16(sp)
    800030fe:	69a2                	ld	s3,8(sp)
    80003100:	6145                	addi	sp,sp,48
    80003102:	8082                	ret
    virtio_disk_rw(b, 0);
    80003104:	4581                	li	a1,0
    80003106:	8526                	mv	a0,s1
    80003108:	00003097          	auipc	ra,0x3
    8000310c:	f1e080e7          	jalr	-226(ra) # 80006026 <virtio_disk_rw>
    b->valid = 1;
    80003110:	4785                	li	a5,1
    80003112:	c09c                	sw	a5,0(s1)
  return b;
    80003114:	b7c5                	j	800030f4 <bread+0xd0>

0000000080003116 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	e426                	sd	s1,8(sp)
    8000311e:	1000                	addi	s0,sp,32
    80003120:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003122:	0541                	addi	a0,a0,16
    80003124:	00001097          	auipc	ra,0x1
    80003128:	46c080e7          	jalr	1132(ra) # 80004590 <holdingsleep>
    8000312c:	cd01                	beqz	a0,80003144 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000312e:	4585                	li	a1,1
    80003130:	8526                	mv	a0,s1
    80003132:	00003097          	auipc	ra,0x3
    80003136:	ef4080e7          	jalr	-268(ra) # 80006026 <virtio_disk_rw>
}
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	64a2                	ld	s1,8(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret
    panic("bwrite");
    80003144:	00005517          	auipc	a0,0x5
    80003148:	60450513          	addi	a0,a0,1540 # 80008748 <syscalls_str+0xe0>
    8000314c:	ffffd097          	auipc	ra,0xffffd
    80003150:	3de080e7          	jalr	990(ra) # 8000052a <panic>

0000000080003154 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	e04a                	sd	s2,0(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003162:	01050913          	addi	s2,a0,16
    80003166:	854a                	mv	a0,s2
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	428080e7          	jalr	1064(ra) # 80004590 <holdingsleep>
    80003170:	c92d                	beqz	a0,800031e2 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003172:	854a                	mv	a0,s2
    80003174:	00001097          	auipc	ra,0x1
    80003178:	3d8080e7          	jalr	984(ra) # 8000454c <releasesleep>

  acquire(&bcache.lock);
    8000317c:	00014517          	auipc	a0,0x14
    80003180:	16c50513          	addi	a0,a0,364 # 800172e8 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	a3e080e7          	jalr	-1474(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000318c:	40bc                	lw	a5,64(s1)
    8000318e:	37fd                	addiw	a5,a5,-1
    80003190:	0007871b          	sext.w	a4,a5
    80003194:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003196:	eb05                	bnez	a4,800031c6 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003198:	68bc                	ld	a5,80(s1)
    8000319a:	64b8                	ld	a4,72(s1)
    8000319c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000319e:	64bc                	ld	a5,72(s1)
    800031a0:	68b8                	ld	a4,80(s1)
    800031a2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031a4:	0001c797          	auipc	a5,0x1c
    800031a8:	14478793          	addi	a5,a5,324 # 8001f2e8 <bcache+0x8000>
    800031ac:	2b87b703          	ld	a4,696(a5)
    800031b0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031b2:	0001c717          	auipc	a4,0x1c
    800031b6:	39e70713          	addi	a4,a4,926 # 8001f550 <bcache+0x8268>
    800031ba:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031bc:	2b87b703          	ld	a4,696(a5)
    800031c0:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031c2:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031c6:	00014517          	auipc	a0,0x14
    800031ca:	12250513          	addi	a0,a0,290 # 800172e8 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	aa8080e7          	jalr	-1368(ra) # 80000c76 <release>
}
    800031d6:	60e2                	ld	ra,24(sp)
    800031d8:	6442                	ld	s0,16(sp)
    800031da:	64a2                	ld	s1,8(sp)
    800031dc:	6902                	ld	s2,0(sp)
    800031de:	6105                	addi	sp,sp,32
    800031e0:	8082                	ret
    panic("brelse");
    800031e2:	00005517          	auipc	a0,0x5
    800031e6:	56e50513          	addi	a0,a0,1390 # 80008750 <syscalls_str+0xe8>
    800031ea:	ffffd097          	auipc	ra,0xffffd
    800031ee:	340080e7          	jalr	832(ra) # 8000052a <panic>

00000000800031f2 <bpin>:

void
bpin(struct buf *b) {
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	e426                	sd	s1,8(sp)
    800031fa:	1000                	addi	s0,sp,32
    800031fc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031fe:	00014517          	auipc	a0,0x14
    80003202:	0ea50513          	addi	a0,a0,234 # 800172e8 <bcache>
    80003206:	ffffe097          	auipc	ra,0xffffe
    8000320a:	9bc080e7          	jalr	-1604(ra) # 80000bc2 <acquire>
  b->refcnt++;
    8000320e:	40bc                	lw	a5,64(s1)
    80003210:	2785                	addiw	a5,a5,1
    80003212:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003214:	00014517          	auipc	a0,0x14
    80003218:	0d450513          	addi	a0,a0,212 # 800172e8 <bcache>
    8000321c:	ffffe097          	auipc	ra,0xffffe
    80003220:	a5a080e7          	jalr	-1446(ra) # 80000c76 <release>
}
    80003224:	60e2                	ld	ra,24(sp)
    80003226:	6442                	ld	s0,16(sp)
    80003228:	64a2                	ld	s1,8(sp)
    8000322a:	6105                	addi	sp,sp,32
    8000322c:	8082                	ret

000000008000322e <bunpin>:

void
bunpin(struct buf *b) {
    8000322e:	1101                	addi	sp,sp,-32
    80003230:	ec06                	sd	ra,24(sp)
    80003232:	e822                	sd	s0,16(sp)
    80003234:	e426                	sd	s1,8(sp)
    80003236:	1000                	addi	s0,sp,32
    80003238:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000323a:	00014517          	auipc	a0,0x14
    8000323e:	0ae50513          	addi	a0,a0,174 # 800172e8 <bcache>
    80003242:	ffffe097          	auipc	ra,0xffffe
    80003246:	980080e7          	jalr	-1664(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000324a:	40bc                	lw	a5,64(s1)
    8000324c:	37fd                	addiw	a5,a5,-1
    8000324e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003250:	00014517          	auipc	a0,0x14
    80003254:	09850513          	addi	a0,a0,152 # 800172e8 <bcache>
    80003258:	ffffe097          	auipc	ra,0xffffe
    8000325c:	a1e080e7          	jalr	-1506(ra) # 80000c76 <release>
}
    80003260:	60e2                	ld	ra,24(sp)
    80003262:	6442                	ld	s0,16(sp)
    80003264:	64a2                	ld	s1,8(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret

000000008000326a <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	e426                	sd	s1,8(sp)
    80003272:	e04a                	sd	s2,0(sp)
    80003274:	1000                	addi	s0,sp,32
    80003276:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003278:	00d5d59b          	srliw	a1,a1,0xd
    8000327c:	0001c797          	auipc	a5,0x1c
    80003280:	7487a783          	lw	a5,1864(a5) # 8001f9c4 <sb+0x1c>
    80003284:	9dbd                	addw	a1,a1,a5
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	d9e080e7          	jalr	-610(ra) # 80003024 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000328e:	0074f713          	andi	a4,s1,7
    80003292:	4785                	li	a5,1
    80003294:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003298:	14ce                	slli	s1,s1,0x33
    8000329a:	90d9                	srli	s1,s1,0x36
    8000329c:	00950733          	add	a4,a0,s1
    800032a0:	05874703          	lbu	a4,88(a4)
    800032a4:	00e7f6b3          	and	a3,a5,a4
    800032a8:	c69d                	beqz	a3,800032d6 <bfree+0x6c>
    800032aa:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032ac:	94aa                	add	s1,s1,a0
    800032ae:	fff7c793          	not	a5,a5
    800032b2:	8ff9                	and	a5,a5,a4
    800032b4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032b8:	00001097          	auipc	ra,0x1
    800032bc:	11e080e7          	jalr	286(ra) # 800043d6 <log_write>
  brelse(bp);
    800032c0:	854a                	mv	a0,s2
    800032c2:	00000097          	auipc	ra,0x0
    800032c6:	e92080e7          	jalr	-366(ra) # 80003154 <brelse>
}
    800032ca:	60e2                	ld	ra,24(sp)
    800032cc:	6442                	ld	s0,16(sp)
    800032ce:	64a2                	ld	s1,8(sp)
    800032d0:	6902                	ld	s2,0(sp)
    800032d2:	6105                	addi	sp,sp,32
    800032d4:	8082                	ret
    panic("freeing free block");
    800032d6:	00005517          	auipc	a0,0x5
    800032da:	48250513          	addi	a0,a0,1154 # 80008758 <syscalls_str+0xf0>
    800032de:	ffffd097          	auipc	ra,0xffffd
    800032e2:	24c080e7          	jalr	588(ra) # 8000052a <panic>

00000000800032e6 <balloc>:
{
    800032e6:	711d                	addi	sp,sp,-96
    800032e8:	ec86                	sd	ra,88(sp)
    800032ea:	e8a2                	sd	s0,80(sp)
    800032ec:	e4a6                	sd	s1,72(sp)
    800032ee:	e0ca                	sd	s2,64(sp)
    800032f0:	fc4e                	sd	s3,56(sp)
    800032f2:	f852                	sd	s4,48(sp)
    800032f4:	f456                	sd	s5,40(sp)
    800032f6:	f05a                	sd	s6,32(sp)
    800032f8:	ec5e                	sd	s7,24(sp)
    800032fa:	e862                	sd	s8,16(sp)
    800032fc:	e466                	sd	s9,8(sp)
    800032fe:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003300:	0001c797          	auipc	a5,0x1c
    80003304:	6ac7a783          	lw	a5,1708(a5) # 8001f9ac <sb+0x4>
    80003308:	cbd1                	beqz	a5,8000339c <balloc+0xb6>
    8000330a:	8baa                	mv	s7,a0
    8000330c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000330e:	0001cb17          	auipc	s6,0x1c
    80003312:	69ab0b13          	addi	s6,s6,1690 # 8001f9a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003316:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003318:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000331a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000331c:	6c89                	lui	s9,0x2
    8000331e:	a831                	j	8000333a <balloc+0x54>
    brelse(bp);
    80003320:	854a                	mv	a0,s2
    80003322:	00000097          	auipc	ra,0x0
    80003326:	e32080e7          	jalr	-462(ra) # 80003154 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000332a:	015c87bb          	addw	a5,s9,s5
    8000332e:	00078a9b          	sext.w	s5,a5
    80003332:	004b2703          	lw	a4,4(s6)
    80003336:	06eaf363          	bgeu	s5,a4,8000339c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000333a:	41fad79b          	sraiw	a5,s5,0x1f
    8000333e:	0137d79b          	srliw	a5,a5,0x13
    80003342:	015787bb          	addw	a5,a5,s5
    80003346:	40d7d79b          	sraiw	a5,a5,0xd
    8000334a:	01cb2583          	lw	a1,28(s6)
    8000334e:	9dbd                	addw	a1,a1,a5
    80003350:	855e                	mv	a0,s7
    80003352:	00000097          	auipc	ra,0x0
    80003356:	cd2080e7          	jalr	-814(ra) # 80003024 <bread>
    8000335a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335c:	004b2503          	lw	a0,4(s6)
    80003360:	000a849b          	sext.w	s1,s5
    80003364:	8662                	mv	a2,s8
    80003366:	faa4fde3          	bgeu	s1,a0,80003320 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000336a:	41f6579b          	sraiw	a5,a2,0x1f
    8000336e:	01d7d69b          	srliw	a3,a5,0x1d
    80003372:	00c6873b          	addw	a4,a3,a2
    80003376:	00777793          	andi	a5,a4,7
    8000337a:	9f95                	subw	a5,a5,a3
    8000337c:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003380:	4037571b          	sraiw	a4,a4,0x3
    80003384:	00e906b3          	add	a3,s2,a4
    80003388:	0586c683          	lbu	a3,88(a3)
    8000338c:	00d7f5b3          	and	a1,a5,a3
    80003390:	cd91                	beqz	a1,800033ac <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003392:	2605                	addiw	a2,a2,1
    80003394:	2485                	addiw	s1,s1,1
    80003396:	fd4618e3          	bne	a2,s4,80003366 <balloc+0x80>
    8000339a:	b759                	j	80003320 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000339c:	00005517          	auipc	a0,0x5
    800033a0:	3d450513          	addi	a0,a0,980 # 80008770 <syscalls_str+0x108>
    800033a4:	ffffd097          	auipc	ra,0xffffd
    800033a8:	186080e7          	jalr	390(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ac:	974a                	add	a4,a4,s2
    800033ae:	8fd5                	or	a5,a5,a3
    800033b0:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033b4:	854a                	mv	a0,s2
    800033b6:	00001097          	auipc	ra,0x1
    800033ba:	020080e7          	jalr	32(ra) # 800043d6 <log_write>
        brelse(bp);
    800033be:	854a                	mv	a0,s2
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	d94080e7          	jalr	-620(ra) # 80003154 <brelse>
  bp = bread(dev, bno);
    800033c8:	85a6                	mv	a1,s1
    800033ca:	855e                	mv	a0,s7
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	c58080e7          	jalr	-936(ra) # 80003024 <bread>
    800033d4:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033d6:	40000613          	li	a2,1024
    800033da:	4581                	li	a1,0
    800033dc:	05850513          	addi	a0,a0,88
    800033e0:	ffffe097          	auipc	ra,0xffffe
    800033e4:	8de080e7          	jalr	-1826(ra) # 80000cbe <memset>
  log_write(bp);
    800033e8:	854a                	mv	a0,s2
    800033ea:	00001097          	auipc	ra,0x1
    800033ee:	fec080e7          	jalr	-20(ra) # 800043d6 <log_write>
  brelse(bp);
    800033f2:	854a                	mv	a0,s2
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	d60080e7          	jalr	-672(ra) # 80003154 <brelse>
}
    800033fc:	8526                	mv	a0,s1
    800033fe:	60e6                	ld	ra,88(sp)
    80003400:	6446                	ld	s0,80(sp)
    80003402:	64a6                	ld	s1,72(sp)
    80003404:	6906                	ld	s2,64(sp)
    80003406:	79e2                	ld	s3,56(sp)
    80003408:	7a42                	ld	s4,48(sp)
    8000340a:	7aa2                	ld	s5,40(sp)
    8000340c:	7b02                	ld	s6,32(sp)
    8000340e:	6be2                	ld	s7,24(sp)
    80003410:	6c42                	ld	s8,16(sp)
    80003412:	6ca2                	ld	s9,8(sp)
    80003414:	6125                	addi	sp,sp,96
    80003416:	8082                	ret

0000000080003418 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003418:	7179                	addi	sp,sp,-48
    8000341a:	f406                	sd	ra,40(sp)
    8000341c:	f022                	sd	s0,32(sp)
    8000341e:	ec26                	sd	s1,24(sp)
    80003420:	e84a                	sd	s2,16(sp)
    80003422:	e44e                	sd	s3,8(sp)
    80003424:	e052                	sd	s4,0(sp)
    80003426:	1800                	addi	s0,sp,48
    80003428:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000342a:	47ad                	li	a5,11
    8000342c:	04b7fe63          	bgeu	a5,a1,80003488 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003430:	ff45849b          	addiw	s1,a1,-12
    80003434:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003438:	0ff00793          	li	a5,255
    8000343c:	0ae7e463          	bltu	a5,a4,800034e4 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003440:	08052583          	lw	a1,128(a0)
    80003444:	c5b5                	beqz	a1,800034b0 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003446:	00092503          	lw	a0,0(s2)
    8000344a:	00000097          	auipc	ra,0x0
    8000344e:	bda080e7          	jalr	-1062(ra) # 80003024 <bread>
    80003452:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003454:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003458:	02049713          	slli	a4,s1,0x20
    8000345c:	01e75593          	srli	a1,a4,0x1e
    80003460:	00b784b3          	add	s1,a5,a1
    80003464:	0004a983          	lw	s3,0(s1)
    80003468:	04098e63          	beqz	s3,800034c4 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    8000346c:	8552                	mv	a0,s4
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	ce6080e7          	jalr	-794(ra) # 80003154 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003476:	854e                	mv	a0,s3
    80003478:	70a2                	ld	ra,40(sp)
    8000347a:	7402                	ld	s0,32(sp)
    8000347c:	64e2                	ld	s1,24(sp)
    8000347e:	6942                	ld	s2,16(sp)
    80003480:	69a2                	ld	s3,8(sp)
    80003482:	6a02                	ld	s4,0(sp)
    80003484:	6145                	addi	sp,sp,48
    80003486:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003488:	02059793          	slli	a5,a1,0x20
    8000348c:	01e7d593          	srli	a1,a5,0x1e
    80003490:	00b504b3          	add	s1,a0,a1
    80003494:	0504a983          	lw	s3,80(s1)
    80003498:	fc099fe3          	bnez	s3,80003476 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000349c:	4108                	lw	a0,0(a0)
    8000349e:	00000097          	auipc	ra,0x0
    800034a2:	e48080e7          	jalr	-440(ra) # 800032e6 <balloc>
    800034a6:	0005099b          	sext.w	s3,a0
    800034aa:	0534a823          	sw	s3,80(s1)
    800034ae:	b7e1                	j	80003476 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034b0:	4108                	lw	a0,0(a0)
    800034b2:	00000097          	auipc	ra,0x0
    800034b6:	e34080e7          	jalr	-460(ra) # 800032e6 <balloc>
    800034ba:	0005059b          	sext.w	a1,a0
    800034be:	08b92023          	sw	a1,128(s2)
    800034c2:	b751                	j	80003446 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034c4:	00092503          	lw	a0,0(s2)
    800034c8:	00000097          	auipc	ra,0x0
    800034cc:	e1e080e7          	jalr	-482(ra) # 800032e6 <balloc>
    800034d0:	0005099b          	sext.w	s3,a0
    800034d4:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034d8:	8552                	mv	a0,s4
    800034da:	00001097          	auipc	ra,0x1
    800034de:	efc080e7          	jalr	-260(ra) # 800043d6 <log_write>
    800034e2:	b769                	j	8000346c <bmap+0x54>
  panic("bmap: out of range");
    800034e4:	00005517          	auipc	a0,0x5
    800034e8:	2a450513          	addi	a0,a0,676 # 80008788 <syscalls_str+0x120>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	03e080e7          	jalr	62(ra) # 8000052a <panic>

00000000800034f4 <iget>:
{
    800034f4:	7179                	addi	sp,sp,-48
    800034f6:	f406                	sd	ra,40(sp)
    800034f8:	f022                	sd	s0,32(sp)
    800034fa:	ec26                	sd	s1,24(sp)
    800034fc:	e84a                	sd	s2,16(sp)
    800034fe:	e44e                	sd	s3,8(sp)
    80003500:	e052                	sd	s4,0(sp)
    80003502:	1800                	addi	s0,sp,48
    80003504:	89aa                	mv	s3,a0
    80003506:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003508:	0001c517          	auipc	a0,0x1c
    8000350c:	4c050513          	addi	a0,a0,1216 # 8001f9c8 <itable>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	6b2080e7          	jalr	1714(ra) # 80000bc2 <acquire>
  empty = 0;
    80003518:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000351a:	0001c497          	auipc	s1,0x1c
    8000351e:	4c648493          	addi	s1,s1,1222 # 8001f9e0 <itable+0x18>
    80003522:	0001e697          	auipc	a3,0x1e
    80003526:	f4e68693          	addi	a3,a3,-178 # 80021470 <log>
    8000352a:	a039                	j	80003538 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000352c:	02090b63          	beqz	s2,80003562 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003530:	08848493          	addi	s1,s1,136
    80003534:	02d48a63          	beq	s1,a3,80003568 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003538:	449c                	lw	a5,8(s1)
    8000353a:	fef059e3          	blez	a5,8000352c <iget+0x38>
    8000353e:	4098                	lw	a4,0(s1)
    80003540:	ff3716e3          	bne	a4,s3,8000352c <iget+0x38>
    80003544:	40d8                	lw	a4,4(s1)
    80003546:	ff4713e3          	bne	a4,s4,8000352c <iget+0x38>
      ip->ref++;
    8000354a:	2785                	addiw	a5,a5,1
    8000354c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000354e:	0001c517          	auipc	a0,0x1c
    80003552:	47a50513          	addi	a0,a0,1146 # 8001f9c8 <itable>
    80003556:	ffffd097          	auipc	ra,0xffffd
    8000355a:	720080e7          	jalr	1824(ra) # 80000c76 <release>
      return ip;
    8000355e:	8926                	mv	s2,s1
    80003560:	a03d                	j	8000358e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003562:	f7f9                	bnez	a5,80003530 <iget+0x3c>
    80003564:	8926                	mv	s2,s1
    80003566:	b7e9                	j	80003530 <iget+0x3c>
  if(empty == 0)
    80003568:	02090c63          	beqz	s2,800035a0 <iget+0xac>
  ip->dev = dev;
    8000356c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003570:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003574:	4785                	li	a5,1
    80003576:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000357a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000357e:	0001c517          	auipc	a0,0x1c
    80003582:	44a50513          	addi	a0,a0,1098 # 8001f9c8 <itable>
    80003586:	ffffd097          	auipc	ra,0xffffd
    8000358a:	6f0080e7          	jalr	1776(ra) # 80000c76 <release>
}
    8000358e:	854a                	mv	a0,s2
    80003590:	70a2                	ld	ra,40(sp)
    80003592:	7402                	ld	s0,32(sp)
    80003594:	64e2                	ld	s1,24(sp)
    80003596:	6942                	ld	s2,16(sp)
    80003598:	69a2                	ld	s3,8(sp)
    8000359a:	6a02                	ld	s4,0(sp)
    8000359c:	6145                	addi	sp,sp,48
    8000359e:	8082                	ret
    panic("iget: no inodes");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	20050513          	addi	a0,a0,512 # 800087a0 <syscalls_str+0x138>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f82080e7          	jalr	-126(ra) # 8000052a <panic>

00000000800035b0 <fsinit>:
fsinit(int dev) {
    800035b0:	7179                	addi	sp,sp,-48
    800035b2:	f406                	sd	ra,40(sp)
    800035b4:	f022                	sd	s0,32(sp)
    800035b6:	ec26                	sd	s1,24(sp)
    800035b8:	e84a                	sd	s2,16(sp)
    800035ba:	e44e                	sd	s3,8(sp)
    800035bc:	1800                	addi	s0,sp,48
    800035be:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035c0:	4585                	li	a1,1
    800035c2:	00000097          	auipc	ra,0x0
    800035c6:	a62080e7          	jalr	-1438(ra) # 80003024 <bread>
    800035ca:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035cc:	0001c997          	auipc	s3,0x1c
    800035d0:	3dc98993          	addi	s3,s3,988 # 8001f9a8 <sb>
    800035d4:	02000613          	li	a2,32
    800035d8:	05850593          	addi	a1,a0,88
    800035dc:	854e                	mv	a0,s3
    800035de:	ffffd097          	auipc	ra,0xffffd
    800035e2:	73c080e7          	jalr	1852(ra) # 80000d1a <memmove>
  brelse(bp);
    800035e6:	8526                	mv	a0,s1
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	b6c080e7          	jalr	-1172(ra) # 80003154 <brelse>
  if(sb.magic != FSMAGIC)
    800035f0:	0009a703          	lw	a4,0(s3)
    800035f4:	102037b7          	lui	a5,0x10203
    800035f8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035fc:	02f71263          	bne	a4,a5,80003620 <fsinit+0x70>
  initlog(dev, &sb);
    80003600:	0001c597          	auipc	a1,0x1c
    80003604:	3a858593          	addi	a1,a1,936 # 8001f9a8 <sb>
    80003608:	854a                	mv	a0,s2
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	b4e080e7          	jalr	-1202(ra) # 80004158 <initlog>
}
    80003612:	70a2                	ld	ra,40(sp)
    80003614:	7402                	ld	s0,32(sp)
    80003616:	64e2                	ld	s1,24(sp)
    80003618:	6942                	ld	s2,16(sp)
    8000361a:	69a2                	ld	s3,8(sp)
    8000361c:	6145                	addi	sp,sp,48
    8000361e:	8082                	ret
    panic("invalid file system");
    80003620:	00005517          	auipc	a0,0x5
    80003624:	19050513          	addi	a0,a0,400 # 800087b0 <syscalls_str+0x148>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	f02080e7          	jalr	-254(ra) # 8000052a <panic>

0000000080003630 <iinit>:
{
    80003630:	7179                	addi	sp,sp,-48
    80003632:	f406                	sd	ra,40(sp)
    80003634:	f022                	sd	s0,32(sp)
    80003636:	ec26                	sd	s1,24(sp)
    80003638:	e84a                	sd	s2,16(sp)
    8000363a:	e44e                	sd	s3,8(sp)
    8000363c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000363e:	00005597          	auipc	a1,0x5
    80003642:	18a58593          	addi	a1,a1,394 # 800087c8 <syscalls_str+0x160>
    80003646:	0001c517          	auipc	a0,0x1c
    8000364a:	38250513          	addi	a0,a0,898 # 8001f9c8 <itable>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	4e4080e7          	jalr	1252(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003656:	0001c497          	auipc	s1,0x1c
    8000365a:	39a48493          	addi	s1,s1,922 # 8001f9f0 <itable+0x28>
    8000365e:	0001e997          	auipc	s3,0x1e
    80003662:	e2298993          	addi	s3,s3,-478 # 80021480 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003666:	00005917          	auipc	s2,0x5
    8000366a:	16a90913          	addi	s2,s2,362 # 800087d0 <syscalls_str+0x168>
    8000366e:	85ca                	mv	a1,s2
    80003670:	8526                	mv	a0,s1
    80003672:	00001097          	auipc	ra,0x1
    80003676:	e4a080e7          	jalr	-438(ra) # 800044bc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000367a:	08848493          	addi	s1,s1,136
    8000367e:	ff3498e3          	bne	s1,s3,8000366e <iinit+0x3e>
}
    80003682:	70a2                	ld	ra,40(sp)
    80003684:	7402                	ld	s0,32(sp)
    80003686:	64e2                	ld	s1,24(sp)
    80003688:	6942                	ld	s2,16(sp)
    8000368a:	69a2                	ld	s3,8(sp)
    8000368c:	6145                	addi	sp,sp,48
    8000368e:	8082                	ret

0000000080003690 <ialloc>:
{
    80003690:	715d                	addi	sp,sp,-80
    80003692:	e486                	sd	ra,72(sp)
    80003694:	e0a2                	sd	s0,64(sp)
    80003696:	fc26                	sd	s1,56(sp)
    80003698:	f84a                	sd	s2,48(sp)
    8000369a:	f44e                	sd	s3,40(sp)
    8000369c:	f052                	sd	s4,32(sp)
    8000369e:	ec56                	sd	s5,24(sp)
    800036a0:	e85a                	sd	s6,16(sp)
    800036a2:	e45e                	sd	s7,8(sp)
    800036a4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036a6:	0001c717          	auipc	a4,0x1c
    800036aa:	30e72703          	lw	a4,782(a4) # 8001f9b4 <sb+0xc>
    800036ae:	4785                	li	a5,1
    800036b0:	04e7fa63          	bgeu	a5,a4,80003704 <ialloc+0x74>
    800036b4:	8aaa                	mv	s5,a0
    800036b6:	8bae                	mv	s7,a1
    800036b8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036ba:	0001ca17          	auipc	s4,0x1c
    800036be:	2eea0a13          	addi	s4,s4,750 # 8001f9a8 <sb>
    800036c2:	00048b1b          	sext.w	s6,s1
    800036c6:	0044d793          	srli	a5,s1,0x4
    800036ca:	018a2583          	lw	a1,24(s4)
    800036ce:	9dbd                	addw	a1,a1,a5
    800036d0:	8556                	mv	a0,s5
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	952080e7          	jalr	-1710(ra) # 80003024 <bread>
    800036da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036dc:	05850993          	addi	s3,a0,88
    800036e0:	00f4f793          	andi	a5,s1,15
    800036e4:	079a                	slli	a5,a5,0x6
    800036e6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036e8:	00099783          	lh	a5,0(s3)
    800036ec:	c785                	beqz	a5,80003714 <ialloc+0x84>
    brelse(bp);
    800036ee:	00000097          	auipc	ra,0x0
    800036f2:	a66080e7          	jalr	-1434(ra) # 80003154 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f6:	0485                	addi	s1,s1,1
    800036f8:	00ca2703          	lw	a4,12(s4)
    800036fc:	0004879b          	sext.w	a5,s1
    80003700:	fce7e1e3          	bltu	a5,a4,800036c2 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003704:	00005517          	auipc	a0,0x5
    80003708:	0d450513          	addi	a0,a0,212 # 800087d8 <syscalls_str+0x170>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	e1e080e7          	jalr	-482(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    80003714:	04000613          	li	a2,64
    80003718:	4581                	li	a1,0
    8000371a:	854e                	mv	a0,s3
    8000371c:	ffffd097          	auipc	ra,0xffffd
    80003720:	5a2080e7          	jalr	1442(ra) # 80000cbe <memset>
      dip->type = type;
    80003724:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	cac080e7          	jalr	-852(ra) # 800043d6 <log_write>
      brelse(bp);
    80003732:	854a                	mv	a0,s2
    80003734:	00000097          	auipc	ra,0x0
    80003738:	a20080e7          	jalr	-1504(ra) # 80003154 <brelse>
      return iget(dev, inum);
    8000373c:	85da                	mv	a1,s6
    8000373e:	8556                	mv	a0,s5
    80003740:	00000097          	auipc	ra,0x0
    80003744:	db4080e7          	jalr	-588(ra) # 800034f4 <iget>
}
    80003748:	60a6                	ld	ra,72(sp)
    8000374a:	6406                	ld	s0,64(sp)
    8000374c:	74e2                	ld	s1,56(sp)
    8000374e:	7942                	ld	s2,48(sp)
    80003750:	79a2                	ld	s3,40(sp)
    80003752:	7a02                	ld	s4,32(sp)
    80003754:	6ae2                	ld	s5,24(sp)
    80003756:	6b42                	ld	s6,16(sp)
    80003758:	6ba2                	ld	s7,8(sp)
    8000375a:	6161                	addi	sp,sp,80
    8000375c:	8082                	ret

000000008000375e <iupdate>:
{
    8000375e:	1101                	addi	sp,sp,-32
    80003760:	ec06                	sd	ra,24(sp)
    80003762:	e822                	sd	s0,16(sp)
    80003764:	e426                	sd	s1,8(sp)
    80003766:	e04a                	sd	s2,0(sp)
    80003768:	1000                	addi	s0,sp,32
    8000376a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000376c:	415c                	lw	a5,4(a0)
    8000376e:	0047d79b          	srliw	a5,a5,0x4
    80003772:	0001c597          	auipc	a1,0x1c
    80003776:	24e5a583          	lw	a1,590(a1) # 8001f9c0 <sb+0x18>
    8000377a:	9dbd                	addw	a1,a1,a5
    8000377c:	4108                	lw	a0,0(a0)
    8000377e:	00000097          	auipc	ra,0x0
    80003782:	8a6080e7          	jalr	-1882(ra) # 80003024 <bread>
    80003786:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003788:	05850793          	addi	a5,a0,88
    8000378c:	40c8                	lw	a0,4(s1)
    8000378e:	893d                	andi	a0,a0,15
    80003790:	051a                	slli	a0,a0,0x6
    80003792:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003794:	04449703          	lh	a4,68(s1)
    80003798:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000379c:	04649703          	lh	a4,70(s1)
    800037a0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037a4:	04849703          	lh	a4,72(s1)
    800037a8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037ac:	04a49703          	lh	a4,74(s1)
    800037b0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037b4:	44f8                	lw	a4,76(s1)
    800037b6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037b8:	03400613          	li	a2,52
    800037bc:	05048593          	addi	a1,s1,80
    800037c0:	0531                	addi	a0,a0,12
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	558080e7          	jalr	1368(ra) # 80000d1a <memmove>
  log_write(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00001097          	auipc	ra,0x1
    800037d0:	c0a080e7          	jalr	-1014(ra) # 800043d6 <log_write>
  brelse(bp);
    800037d4:	854a                	mv	a0,s2
    800037d6:	00000097          	auipc	ra,0x0
    800037da:	97e080e7          	jalr	-1666(ra) # 80003154 <brelse>
}
    800037de:	60e2                	ld	ra,24(sp)
    800037e0:	6442                	ld	s0,16(sp)
    800037e2:	64a2                	ld	s1,8(sp)
    800037e4:	6902                	ld	s2,0(sp)
    800037e6:	6105                	addi	sp,sp,32
    800037e8:	8082                	ret

00000000800037ea <idup>:
{
    800037ea:	1101                	addi	sp,sp,-32
    800037ec:	ec06                	sd	ra,24(sp)
    800037ee:	e822                	sd	s0,16(sp)
    800037f0:	e426                	sd	s1,8(sp)
    800037f2:	1000                	addi	s0,sp,32
    800037f4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800037f6:	0001c517          	auipc	a0,0x1c
    800037fa:	1d250513          	addi	a0,a0,466 # 8001f9c8 <itable>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	3c4080e7          	jalr	964(ra) # 80000bc2 <acquire>
  ip->ref++;
    80003806:	449c                	lw	a5,8(s1)
    80003808:	2785                	addiw	a5,a5,1
    8000380a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000380c:	0001c517          	auipc	a0,0x1c
    80003810:	1bc50513          	addi	a0,a0,444 # 8001f9c8 <itable>
    80003814:	ffffd097          	auipc	ra,0xffffd
    80003818:	462080e7          	jalr	1122(ra) # 80000c76 <release>
}
    8000381c:	8526                	mv	a0,s1
    8000381e:	60e2                	ld	ra,24(sp)
    80003820:	6442                	ld	s0,16(sp)
    80003822:	64a2                	ld	s1,8(sp)
    80003824:	6105                	addi	sp,sp,32
    80003826:	8082                	ret

0000000080003828 <ilock>:
{
    80003828:	1101                	addi	sp,sp,-32
    8000382a:	ec06                	sd	ra,24(sp)
    8000382c:	e822                	sd	s0,16(sp)
    8000382e:	e426                	sd	s1,8(sp)
    80003830:	e04a                	sd	s2,0(sp)
    80003832:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003834:	c115                	beqz	a0,80003858 <ilock+0x30>
    80003836:	84aa                	mv	s1,a0
    80003838:	451c                	lw	a5,8(a0)
    8000383a:	00f05f63          	blez	a5,80003858 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000383e:	0541                	addi	a0,a0,16
    80003840:	00001097          	auipc	ra,0x1
    80003844:	cb6080e7          	jalr	-842(ra) # 800044f6 <acquiresleep>
  if(ip->valid == 0){
    80003848:	40bc                	lw	a5,64(s1)
    8000384a:	cf99                	beqz	a5,80003868 <ilock+0x40>
}
    8000384c:	60e2                	ld	ra,24(sp)
    8000384e:	6442                	ld	s0,16(sp)
    80003850:	64a2                	ld	s1,8(sp)
    80003852:	6902                	ld	s2,0(sp)
    80003854:	6105                	addi	sp,sp,32
    80003856:	8082                	ret
    panic("ilock");
    80003858:	00005517          	auipc	a0,0x5
    8000385c:	f9850513          	addi	a0,a0,-104 # 800087f0 <syscalls_str+0x188>
    80003860:	ffffd097          	auipc	ra,0xffffd
    80003864:	cca080e7          	jalr	-822(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003868:	40dc                	lw	a5,4(s1)
    8000386a:	0047d79b          	srliw	a5,a5,0x4
    8000386e:	0001c597          	auipc	a1,0x1c
    80003872:	1525a583          	lw	a1,338(a1) # 8001f9c0 <sb+0x18>
    80003876:	9dbd                	addw	a1,a1,a5
    80003878:	4088                	lw	a0,0(s1)
    8000387a:	fffff097          	auipc	ra,0xfffff
    8000387e:	7aa080e7          	jalr	1962(ra) # 80003024 <bread>
    80003882:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003884:	05850593          	addi	a1,a0,88
    80003888:	40dc                	lw	a5,4(s1)
    8000388a:	8bbd                	andi	a5,a5,15
    8000388c:	079a                	slli	a5,a5,0x6
    8000388e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003890:	00059783          	lh	a5,0(a1)
    80003894:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003898:	00259783          	lh	a5,2(a1)
    8000389c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038a0:	00459783          	lh	a5,4(a1)
    800038a4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038a8:	00659783          	lh	a5,6(a1)
    800038ac:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038b0:	459c                	lw	a5,8(a1)
    800038b2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038b4:	03400613          	li	a2,52
    800038b8:	05b1                	addi	a1,a1,12
    800038ba:	05048513          	addi	a0,s1,80
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	45c080e7          	jalr	1116(ra) # 80000d1a <memmove>
    brelse(bp);
    800038c6:	854a                	mv	a0,s2
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	88c080e7          	jalr	-1908(ra) # 80003154 <brelse>
    ip->valid = 1;
    800038d0:	4785                	li	a5,1
    800038d2:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038d4:	04449783          	lh	a5,68(s1)
    800038d8:	fbb5                	bnez	a5,8000384c <ilock+0x24>
      panic("ilock: no type");
    800038da:	00005517          	auipc	a0,0x5
    800038de:	f1e50513          	addi	a0,a0,-226 # 800087f8 <syscalls_str+0x190>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	c48080e7          	jalr	-952(ra) # 8000052a <panic>

00000000800038ea <iunlock>:
{
    800038ea:	1101                	addi	sp,sp,-32
    800038ec:	ec06                	sd	ra,24(sp)
    800038ee:	e822                	sd	s0,16(sp)
    800038f0:	e426                	sd	s1,8(sp)
    800038f2:	e04a                	sd	s2,0(sp)
    800038f4:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038f6:	c905                	beqz	a0,80003926 <iunlock+0x3c>
    800038f8:	84aa                	mv	s1,a0
    800038fa:	01050913          	addi	s2,a0,16
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	c90080e7          	jalr	-880(ra) # 80004590 <holdingsleep>
    80003908:	cd19                	beqz	a0,80003926 <iunlock+0x3c>
    8000390a:	449c                	lw	a5,8(s1)
    8000390c:	00f05d63          	blez	a5,80003926 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	c3a080e7          	jalr	-966(ra) # 8000454c <releasesleep>
}
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6902                	ld	s2,0(sp)
    80003922:	6105                	addi	sp,sp,32
    80003924:	8082                	ret
    panic("iunlock");
    80003926:	00005517          	auipc	a0,0x5
    8000392a:	ee250513          	addi	a0,a0,-286 # 80008808 <syscalls_str+0x1a0>
    8000392e:	ffffd097          	auipc	ra,0xffffd
    80003932:	bfc080e7          	jalr	-1028(ra) # 8000052a <panic>

0000000080003936 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003936:	7179                	addi	sp,sp,-48
    80003938:	f406                	sd	ra,40(sp)
    8000393a:	f022                	sd	s0,32(sp)
    8000393c:	ec26                	sd	s1,24(sp)
    8000393e:	e84a                	sd	s2,16(sp)
    80003940:	e44e                	sd	s3,8(sp)
    80003942:	e052                	sd	s4,0(sp)
    80003944:	1800                	addi	s0,sp,48
    80003946:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003948:	05050493          	addi	s1,a0,80
    8000394c:	08050913          	addi	s2,a0,128
    80003950:	a021                	j	80003958 <itrunc+0x22>
    80003952:	0491                	addi	s1,s1,4
    80003954:	01248d63          	beq	s1,s2,8000396e <itrunc+0x38>
    if(ip->addrs[i]){
    80003958:	408c                	lw	a1,0(s1)
    8000395a:	dde5                	beqz	a1,80003952 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000395c:	0009a503          	lw	a0,0(s3)
    80003960:	00000097          	auipc	ra,0x0
    80003964:	90a080e7          	jalr	-1782(ra) # 8000326a <bfree>
      ip->addrs[i] = 0;
    80003968:	0004a023          	sw	zero,0(s1)
    8000396c:	b7dd                	j	80003952 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000396e:	0809a583          	lw	a1,128(s3)
    80003972:	e185                	bnez	a1,80003992 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003974:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003978:	854e                	mv	a0,s3
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	de4080e7          	jalr	-540(ra) # 8000375e <iupdate>
}
    80003982:	70a2                	ld	ra,40(sp)
    80003984:	7402                	ld	s0,32(sp)
    80003986:	64e2                	ld	s1,24(sp)
    80003988:	6942                	ld	s2,16(sp)
    8000398a:	69a2                	ld	s3,8(sp)
    8000398c:	6a02                	ld	s4,0(sp)
    8000398e:	6145                	addi	sp,sp,48
    80003990:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003992:	0009a503          	lw	a0,0(s3)
    80003996:	fffff097          	auipc	ra,0xfffff
    8000399a:	68e080e7          	jalr	1678(ra) # 80003024 <bread>
    8000399e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039a0:	05850493          	addi	s1,a0,88
    800039a4:	45850913          	addi	s2,a0,1112
    800039a8:	a021                	j	800039b0 <itrunc+0x7a>
    800039aa:	0491                	addi	s1,s1,4
    800039ac:	01248b63          	beq	s1,s2,800039c2 <itrunc+0x8c>
      if(a[j])
    800039b0:	408c                	lw	a1,0(s1)
    800039b2:	dde5                	beqz	a1,800039aa <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800039b4:	0009a503          	lw	a0,0(s3)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	8b2080e7          	jalr	-1870(ra) # 8000326a <bfree>
    800039c0:	b7ed                	j	800039aa <itrunc+0x74>
    brelse(bp);
    800039c2:	8552                	mv	a0,s4
    800039c4:	fffff097          	auipc	ra,0xfffff
    800039c8:	790080e7          	jalr	1936(ra) # 80003154 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039cc:	0809a583          	lw	a1,128(s3)
    800039d0:	0009a503          	lw	a0,0(s3)
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	896080e7          	jalr	-1898(ra) # 8000326a <bfree>
    ip->addrs[NDIRECT] = 0;
    800039dc:	0809a023          	sw	zero,128(s3)
    800039e0:	bf51                	j	80003974 <itrunc+0x3e>

00000000800039e2 <iput>:
{
    800039e2:	1101                	addi	sp,sp,-32
    800039e4:	ec06                	sd	ra,24(sp)
    800039e6:	e822                	sd	s0,16(sp)
    800039e8:	e426                	sd	s1,8(sp)
    800039ea:	e04a                	sd	s2,0(sp)
    800039ec:	1000                	addi	s0,sp,32
    800039ee:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039f0:	0001c517          	auipc	a0,0x1c
    800039f4:	fd850513          	addi	a0,a0,-40 # 8001f9c8 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	1ca080e7          	jalr	458(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a00:	4498                	lw	a4,8(s1)
    80003a02:	4785                	li	a5,1
    80003a04:	02f70363          	beq	a4,a5,80003a2a <iput+0x48>
  ip->ref--;
    80003a08:	449c                	lw	a5,8(s1)
    80003a0a:	37fd                	addiw	a5,a5,-1
    80003a0c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a0e:	0001c517          	auipc	a0,0x1c
    80003a12:	fba50513          	addi	a0,a0,-70 # 8001f9c8 <itable>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	260080e7          	jalr	608(ra) # 80000c76 <release>
}
    80003a1e:	60e2                	ld	ra,24(sp)
    80003a20:	6442                	ld	s0,16(sp)
    80003a22:	64a2                	ld	s1,8(sp)
    80003a24:	6902                	ld	s2,0(sp)
    80003a26:	6105                	addi	sp,sp,32
    80003a28:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a2a:	40bc                	lw	a5,64(s1)
    80003a2c:	dff1                	beqz	a5,80003a08 <iput+0x26>
    80003a2e:	04a49783          	lh	a5,74(s1)
    80003a32:	fbf9                	bnez	a5,80003a08 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a34:	01048913          	addi	s2,s1,16
    80003a38:	854a                	mv	a0,s2
    80003a3a:	00001097          	auipc	ra,0x1
    80003a3e:	abc080e7          	jalr	-1348(ra) # 800044f6 <acquiresleep>
    release(&itable.lock);
    80003a42:	0001c517          	auipc	a0,0x1c
    80003a46:	f8650513          	addi	a0,a0,-122 # 8001f9c8 <itable>
    80003a4a:	ffffd097          	auipc	ra,0xffffd
    80003a4e:	22c080e7          	jalr	556(ra) # 80000c76 <release>
    itrunc(ip);
    80003a52:	8526                	mv	a0,s1
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	ee2080e7          	jalr	-286(ra) # 80003936 <itrunc>
    ip->type = 0;
    80003a5c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a60:	8526                	mv	a0,s1
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	cfc080e7          	jalr	-772(ra) # 8000375e <iupdate>
    ip->valid = 0;
    80003a6a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a6e:	854a                	mv	a0,s2
    80003a70:	00001097          	auipc	ra,0x1
    80003a74:	adc080e7          	jalr	-1316(ra) # 8000454c <releasesleep>
    acquire(&itable.lock);
    80003a78:	0001c517          	auipc	a0,0x1c
    80003a7c:	f5050513          	addi	a0,a0,-176 # 8001f9c8 <itable>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	142080e7          	jalr	322(ra) # 80000bc2 <acquire>
    80003a88:	b741                	j	80003a08 <iput+0x26>

0000000080003a8a <iunlockput>:
{
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	1000                	addi	s0,sp,32
    80003a94:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a96:	00000097          	auipc	ra,0x0
    80003a9a:	e54080e7          	jalr	-428(ra) # 800038ea <iunlock>
  iput(ip);
    80003a9e:	8526                	mv	a0,s1
    80003aa0:	00000097          	auipc	ra,0x0
    80003aa4:	f42080e7          	jalr	-190(ra) # 800039e2 <iput>
}
    80003aa8:	60e2                	ld	ra,24(sp)
    80003aaa:	6442                	ld	s0,16(sp)
    80003aac:	64a2                	ld	s1,8(sp)
    80003aae:	6105                	addi	sp,sp,32
    80003ab0:	8082                	ret

0000000080003ab2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ab2:	1141                	addi	sp,sp,-16
    80003ab4:	e422                	sd	s0,8(sp)
    80003ab6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ab8:	411c                	lw	a5,0(a0)
    80003aba:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003abc:	415c                	lw	a5,4(a0)
    80003abe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ac0:	04451783          	lh	a5,68(a0)
    80003ac4:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ac8:	04a51783          	lh	a5,74(a0)
    80003acc:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ad0:	04c56783          	lwu	a5,76(a0)
    80003ad4:	e99c                	sd	a5,16(a1)
}
    80003ad6:	6422                	ld	s0,8(sp)
    80003ad8:	0141                	addi	sp,sp,16
    80003ada:	8082                	ret

0000000080003adc <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003adc:	457c                	lw	a5,76(a0)
    80003ade:	0ed7e963          	bltu	a5,a3,80003bd0 <readi+0xf4>
{
    80003ae2:	7159                	addi	sp,sp,-112
    80003ae4:	f486                	sd	ra,104(sp)
    80003ae6:	f0a2                	sd	s0,96(sp)
    80003ae8:	eca6                	sd	s1,88(sp)
    80003aea:	e8ca                	sd	s2,80(sp)
    80003aec:	e4ce                	sd	s3,72(sp)
    80003aee:	e0d2                	sd	s4,64(sp)
    80003af0:	fc56                	sd	s5,56(sp)
    80003af2:	f85a                	sd	s6,48(sp)
    80003af4:	f45e                	sd	s7,40(sp)
    80003af6:	f062                	sd	s8,32(sp)
    80003af8:	ec66                	sd	s9,24(sp)
    80003afa:	e86a                	sd	s10,16(sp)
    80003afc:	e46e                	sd	s11,8(sp)
    80003afe:	1880                	addi	s0,sp,112
    80003b00:	8baa                	mv	s7,a0
    80003b02:	8c2e                	mv	s8,a1
    80003b04:	8ab2                	mv	s5,a2
    80003b06:	84b6                	mv	s1,a3
    80003b08:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b0a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b0c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b0e:	0ad76063          	bltu	a4,a3,80003bae <readi+0xd2>
  if(off + n > ip->size)
    80003b12:	00e7f463          	bgeu	a5,a4,80003b1a <readi+0x3e>
    n = ip->size - off;
    80003b16:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b1a:	0a0b0963          	beqz	s6,80003bcc <readi+0xf0>
    80003b1e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b20:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b24:	5cfd                	li	s9,-1
    80003b26:	a82d                	j	80003b60 <readi+0x84>
    80003b28:	020a1d93          	slli	s11,s4,0x20
    80003b2c:	020ddd93          	srli	s11,s11,0x20
    80003b30:	05890793          	addi	a5,s2,88
    80003b34:	86ee                	mv	a3,s11
    80003b36:	963e                	add	a2,a2,a5
    80003b38:	85d6                	mv	a1,s5
    80003b3a:	8562                	mv	a0,s8
    80003b3c:	fffff097          	auipc	ra,0xfffff
    80003b40:	9ac080e7          	jalr	-1620(ra) # 800024e8 <either_copyout>
    80003b44:	05950d63          	beq	a0,s9,80003b9e <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	fffff097          	auipc	ra,0xfffff
    80003b4e:	60a080e7          	jalr	1546(ra) # 80003154 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b52:	013a09bb          	addw	s3,s4,s3
    80003b56:	009a04bb          	addw	s1,s4,s1
    80003b5a:	9aee                	add	s5,s5,s11
    80003b5c:	0569f763          	bgeu	s3,s6,80003baa <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b60:	000ba903          	lw	s2,0(s7)
    80003b64:	00a4d59b          	srliw	a1,s1,0xa
    80003b68:	855e                	mv	a0,s7
    80003b6a:	00000097          	auipc	ra,0x0
    80003b6e:	8ae080e7          	jalr	-1874(ra) # 80003418 <bmap>
    80003b72:	0005059b          	sext.w	a1,a0
    80003b76:	854a                	mv	a0,s2
    80003b78:	fffff097          	auipc	ra,0xfffff
    80003b7c:	4ac080e7          	jalr	1196(ra) # 80003024 <bread>
    80003b80:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b82:	3ff4f613          	andi	a2,s1,1023
    80003b86:	40cd07bb          	subw	a5,s10,a2
    80003b8a:	413b073b          	subw	a4,s6,s3
    80003b8e:	8a3e                	mv	s4,a5
    80003b90:	2781                	sext.w	a5,a5
    80003b92:	0007069b          	sext.w	a3,a4
    80003b96:	f8f6f9e3          	bgeu	a3,a5,80003b28 <readi+0x4c>
    80003b9a:	8a3a                	mv	s4,a4
    80003b9c:	b771                	j	80003b28 <readi+0x4c>
      brelse(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	5b4080e7          	jalr	1460(ra) # 80003154 <brelse>
      tot = -1;
    80003ba8:	59fd                	li	s3,-1
  }
  return tot;
    80003baa:	0009851b          	sext.w	a0,s3
}
    80003bae:	70a6                	ld	ra,104(sp)
    80003bb0:	7406                	ld	s0,96(sp)
    80003bb2:	64e6                	ld	s1,88(sp)
    80003bb4:	6946                	ld	s2,80(sp)
    80003bb6:	69a6                	ld	s3,72(sp)
    80003bb8:	6a06                	ld	s4,64(sp)
    80003bba:	7ae2                	ld	s5,56(sp)
    80003bbc:	7b42                	ld	s6,48(sp)
    80003bbe:	7ba2                	ld	s7,40(sp)
    80003bc0:	7c02                	ld	s8,32(sp)
    80003bc2:	6ce2                	ld	s9,24(sp)
    80003bc4:	6d42                	ld	s10,16(sp)
    80003bc6:	6da2                	ld	s11,8(sp)
    80003bc8:	6165                	addi	sp,sp,112
    80003bca:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bcc:	89da                	mv	s3,s6
    80003bce:	bff1                	j	80003baa <readi+0xce>
    return 0;
    80003bd0:	4501                	li	a0,0
}
    80003bd2:	8082                	ret

0000000080003bd4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bd4:	457c                	lw	a5,76(a0)
    80003bd6:	10d7e863          	bltu	a5,a3,80003ce6 <writei+0x112>
{
    80003bda:	7159                	addi	sp,sp,-112
    80003bdc:	f486                	sd	ra,104(sp)
    80003bde:	f0a2                	sd	s0,96(sp)
    80003be0:	eca6                	sd	s1,88(sp)
    80003be2:	e8ca                	sd	s2,80(sp)
    80003be4:	e4ce                	sd	s3,72(sp)
    80003be6:	e0d2                	sd	s4,64(sp)
    80003be8:	fc56                	sd	s5,56(sp)
    80003bea:	f85a                	sd	s6,48(sp)
    80003bec:	f45e                	sd	s7,40(sp)
    80003bee:	f062                	sd	s8,32(sp)
    80003bf0:	ec66                	sd	s9,24(sp)
    80003bf2:	e86a                	sd	s10,16(sp)
    80003bf4:	e46e                	sd	s11,8(sp)
    80003bf6:	1880                	addi	s0,sp,112
    80003bf8:	8b2a                	mv	s6,a0
    80003bfa:	8c2e                	mv	s8,a1
    80003bfc:	8ab2                	mv	s5,a2
    80003bfe:	8936                	mv	s2,a3
    80003c00:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003c02:	00e687bb          	addw	a5,a3,a4
    80003c06:	0ed7e263          	bltu	a5,a3,80003cea <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c0a:	00043737          	lui	a4,0x43
    80003c0e:	0ef76063          	bltu	a4,a5,80003cee <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c12:	0c0b8863          	beqz	s7,80003ce2 <writei+0x10e>
    80003c16:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c18:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c1c:	5cfd                	li	s9,-1
    80003c1e:	a091                	j	80003c62 <writei+0x8e>
    80003c20:	02099d93          	slli	s11,s3,0x20
    80003c24:	020ddd93          	srli	s11,s11,0x20
    80003c28:	05848793          	addi	a5,s1,88
    80003c2c:	86ee                	mv	a3,s11
    80003c2e:	8656                	mv	a2,s5
    80003c30:	85e2                	mv	a1,s8
    80003c32:	953e                	add	a0,a0,a5
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	90a080e7          	jalr	-1782(ra) # 8000253e <either_copyin>
    80003c3c:	07950263          	beq	a0,s9,80003ca0 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c40:	8526                	mv	a0,s1
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	794080e7          	jalr	1940(ra) # 800043d6 <log_write>
    brelse(bp);
    80003c4a:	8526                	mv	a0,s1
    80003c4c:	fffff097          	auipc	ra,0xfffff
    80003c50:	508080e7          	jalr	1288(ra) # 80003154 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c54:	01498a3b          	addw	s4,s3,s4
    80003c58:	0129893b          	addw	s2,s3,s2
    80003c5c:	9aee                	add	s5,s5,s11
    80003c5e:	057a7663          	bgeu	s4,s7,80003caa <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c62:	000b2483          	lw	s1,0(s6)
    80003c66:	00a9559b          	srliw	a1,s2,0xa
    80003c6a:	855a                	mv	a0,s6
    80003c6c:	fffff097          	auipc	ra,0xfffff
    80003c70:	7ac080e7          	jalr	1964(ra) # 80003418 <bmap>
    80003c74:	0005059b          	sext.w	a1,a0
    80003c78:	8526                	mv	a0,s1
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	3aa080e7          	jalr	938(ra) # 80003024 <bread>
    80003c82:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c84:	3ff97513          	andi	a0,s2,1023
    80003c88:	40ad07bb          	subw	a5,s10,a0
    80003c8c:	414b873b          	subw	a4,s7,s4
    80003c90:	89be                	mv	s3,a5
    80003c92:	2781                	sext.w	a5,a5
    80003c94:	0007069b          	sext.w	a3,a4
    80003c98:	f8f6f4e3          	bgeu	a3,a5,80003c20 <writei+0x4c>
    80003c9c:	89ba                	mv	s3,a4
    80003c9e:	b749                	j	80003c20 <writei+0x4c>
      brelse(bp);
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	4b2080e7          	jalr	1202(ra) # 80003154 <brelse>
  }

  if(off > ip->size)
    80003caa:	04cb2783          	lw	a5,76(s6)
    80003cae:	0127f463          	bgeu	a5,s2,80003cb6 <writei+0xe2>
    ip->size = off;
    80003cb2:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003cb6:	855a                	mv	a0,s6
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	aa6080e7          	jalr	-1370(ra) # 8000375e <iupdate>

  return tot;
    80003cc0:	000a051b          	sext.w	a0,s4
}
    80003cc4:	70a6                	ld	ra,104(sp)
    80003cc6:	7406                	ld	s0,96(sp)
    80003cc8:	64e6                	ld	s1,88(sp)
    80003cca:	6946                	ld	s2,80(sp)
    80003ccc:	69a6                	ld	s3,72(sp)
    80003cce:	6a06                	ld	s4,64(sp)
    80003cd0:	7ae2                	ld	s5,56(sp)
    80003cd2:	7b42                	ld	s6,48(sp)
    80003cd4:	7ba2                	ld	s7,40(sp)
    80003cd6:	7c02                	ld	s8,32(sp)
    80003cd8:	6ce2                	ld	s9,24(sp)
    80003cda:	6d42                	ld	s10,16(sp)
    80003cdc:	6da2                	ld	s11,8(sp)
    80003cde:	6165                	addi	sp,sp,112
    80003ce0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ce2:	8a5e                	mv	s4,s7
    80003ce4:	bfc9                	j	80003cb6 <writei+0xe2>
    return -1;
    80003ce6:	557d                	li	a0,-1
}
    80003ce8:	8082                	ret
    return -1;
    80003cea:	557d                	li	a0,-1
    80003cec:	bfe1                	j	80003cc4 <writei+0xf0>
    return -1;
    80003cee:	557d                	li	a0,-1
    80003cf0:	bfd1                	j	80003cc4 <writei+0xf0>

0000000080003cf2 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cf2:	1141                	addi	sp,sp,-16
    80003cf4:	e406                	sd	ra,8(sp)
    80003cf6:	e022                	sd	s0,0(sp)
    80003cf8:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cfa:	4639                	li	a2,14
    80003cfc:	ffffd097          	auipc	ra,0xffffd
    80003d00:	09a080e7          	jalr	154(ra) # 80000d96 <strncmp>
}
    80003d04:	60a2                	ld	ra,8(sp)
    80003d06:	6402                	ld	s0,0(sp)
    80003d08:	0141                	addi	sp,sp,16
    80003d0a:	8082                	ret

0000000080003d0c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d0c:	7139                	addi	sp,sp,-64
    80003d0e:	fc06                	sd	ra,56(sp)
    80003d10:	f822                	sd	s0,48(sp)
    80003d12:	f426                	sd	s1,40(sp)
    80003d14:	f04a                	sd	s2,32(sp)
    80003d16:	ec4e                	sd	s3,24(sp)
    80003d18:	e852                	sd	s4,16(sp)
    80003d1a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d1c:	04451703          	lh	a4,68(a0)
    80003d20:	4785                	li	a5,1
    80003d22:	00f71a63          	bne	a4,a5,80003d36 <dirlookup+0x2a>
    80003d26:	892a                	mv	s2,a0
    80003d28:	89ae                	mv	s3,a1
    80003d2a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2c:	457c                	lw	a5,76(a0)
    80003d2e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d30:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d32:	e79d                	bnez	a5,80003d60 <dirlookup+0x54>
    80003d34:	a8a5                	j	80003dac <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d36:	00005517          	auipc	a0,0x5
    80003d3a:	ada50513          	addi	a0,a0,-1318 # 80008810 <syscalls_str+0x1a8>
    80003d3e:	ffffc097          	auipc	ra,0xffffc
    80003d42:	7ec080e7          	jalr	2028(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003d46:	00005517          	auipc	a0,0x5
    80003d4a:	ae250513          	addi	a0,a0,-1310 # 80008828 <syscalls_str+0x1c0>
    80003d4e:	ffffc097          	auipc	ra,0xffffc
    80003d52:	7dc080e7          	jalr	2012(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d56:	24c1                	addiw	s1,s1,16
    80003d58:	04c92783          	lw	a5,76(s2)
    80003d5c:	04f4f763          	bgeu	s1,a5,80003daa <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d60:	4741                	li	a4,16
    80003d62:	86a6                	mv	a3,s1
    80003d64:	fc040613          	addi	a2,s0,-64
    80003d68:	4581                	li	a1,0
    80003d6a:	854a                	mv	a0,s2
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	d70080e7          	jalr	-656(ra) # 80003adc <readi>
    80003d74:	47c1                	li	a5,16
    80003d76:	fcf518e3          	bne	a0,a5,80003d46 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d7a:	fc045783          	lhu	a5,-64(s0)
    80003d7e:	dfe1                	beqz	a5,80003d56 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d80:	fc240593          	addi	a1,s0,-62
    80003d84:	854e                	mv	a0,s3
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	f6c080e7          	jalr	-148(ra) # 80003cf2 <namecmp>
    80003d8e:	f561                	bnez	a0,80003d56 <dirlookup+0x4a>
      if(poff)
    80003d90:	000a0463          	beqz	s4,80003d98 <dirlookup+0x8c>
        *poff = off;
    80003d94:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d98:	fc045583          	lhu	a1,-64(s0)
    80003d9c:	00092503          	lw	a0,0(s2)
    80003da0:	fffff097          	auipc	ra,0xfffff
    80003da4:	754080e7          	jalr	1876(ra) # 800034f4 <iget>
    80003da8:	a011                	j	80003dac <dirlookup+0xa0>
  return 0;
    80003daa:	4501                	li	a0,0
}
    80003dac:	70e2                	ld	ra,56(sp)
    80003dae:	7442                	ld	s0,48(sp)
    80003db0:	74a2                	ld	s1,40(sp)
    80003db2:	7902                	ld	s2,32(sp)
    80003db4:	69e2                	ld	s3,24(sp)
    80003db6:	6a42                	ld	s4,16(sp)
    80003db8:	6121                	addi	sp,sp,64
    80003dba:	8082                	ret

0000000080003dbc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003dbc:	711d                	addi	sp,sp,-96
    80003dbe:	ec86                	sd	ra,88(sp)
    80003dc0:	e8a2                	sd	s0,80(sp)
    80003dc2:	e4a6                	sd	s1,72(sp)
    80003dc4:	e0ca                	sd	s2,64(sp)
    80003dc6:	fc4e                	sd	s3,56(sp)
    80003dc8:	f852                	sd	s4,48(sp)
    80003dca:	f456                	sd	s5,40(sp)
    80003dcc:	f05a                	sd	s6,32(sp)
    80003dce:	ec5e                	sd	s7,24(sp)
    80003dd0:	e862                	sd	s8,16(sp)
    80003dd2:	e466                	sd	s9,8(sp)
    80003dd4:	1080                	addi	s0,sp,96
    80003dd6:	84aa                	mv	s1,a0
    80003dd8:	8aae                	mv	s5,a1
    80003dda:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ddc:	00054703          	lbu	a4,0(a0)
    80003de0:	02f00793          	li	a5,47
    80003de4:	02f70363          	beq	a4,a5,80003e0a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003de8:	ffffe097          	auipc	ra,0xffffe
    80003dec:	baa080e7          	jalr	-1110(ra) # 80001992 <myproc>
    80003df0:	15053503          	ld	a0,336(a0)
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	9f6080e7          	jalr	-1546(ra) # 800037ea <idup>
    80003dfc:	89aa                	mv	s3,a0
  while(*path == '/')
    80003dfe:	02f00913          	li	s2,47
  len = path - s;
    80003e02:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003e04:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e06:	4b85                	li	s7,1
    80003e08:	a865                	j	80003ec0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e0a:	4585                	li	a1,1
    80003e0c:	4505                	li	a0,1
    80003e0e:	fffff097          	auipc	ra,0xfffff
    80003e12:	6e6080e7          	jalr	1766(ra) # 800034f4 <iget>
    80003e16:	89aa                	mv	s3,a0
    80003e18:	b7dd                	j	80003dfe <namex+0x42>
      iunlockput(ip);
    80003e1a:	854e                	mv	a0,s3
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	c6e080e7          	jalr	-914(ra) # 80003a8a <iunlockput>
      return 0;
    80003e24:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e26:	854e                	mv	a0,s3
    80003e28:	60e6                	ld	ra,88(sp)
    80003e2a:	6446                	ld	s0,80(sp)
    80003e2c:	64a6                	ld	s1,72(sp)
    80003e2e:	6906                	ld	s2,64(sp)
    80003e30:	79e2                	ld	s3,56(sp)
    80003e32:	7a42                	ld	s4,48(sp)
    80003e34:	7aa2                	ld	s5,40(sp)
    80003e36:	7b02                	ld	s6,32(sp)
    80003e38:	6be2                	ld	s7,24(sp)
    80003e3a:	6c42                	ld	s8,16(sp)
    80003e3c:	6ca2                	ld	s9,8(sp)
    80003e3e:	6125                	addi	sp,sp,96
    80003e40:	8082                	ret
      iunlock(ip);
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	aa6080e7          	jalr	-1370(ra) # 800038ea <iunlock>
      return ip;
    80003e4c:	bfe9                	j	80003e26 <namex+0x6a>
      iunlockput(ip);
    80003e4e:	854e                	mv	a0,s3
    80003e50:	00000097          	auipc	ra,0x0
    80003e54:	c3a080e7          	jalr	-966(ra) # 80003a8a <iunlockput>
      return 0;
    80003e58:	89e6                	mv	s3,s9
    80003e5a:	b7f1                	j	80003e26 <namex+0x6a>
  len = path - s;
    80003e5c:	40b48633          	sub	a2,s1,a1
    80003e60:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003e64:	099c5463          	bge	s8,s9,80003eec <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e68:	4639                	li	a2,14
    80003e6a:	8552                	mv	a0,s4
    80003e6c:	ffffd097          	auipc	ra,0xffffd
    80003e70:	eae080e7          	jalr	-338(ra) # 80000d1a <memmove>
  while(*path == '/')
    80003e74:	0004c783          	lbu	a5,0(s1)
    80003e78:	01279763          	bne	a5,s2,80003e86 <namex+0xca>
    path++;
    80003e7c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e7e:	0004c783          	lbu	a5,0(s1)
    80003e82:	ff278de3          	beq	a5,s2,80003e7c <namex+0xc0>
    ilock(ip);
    80003e86:	854e                	mv	a0,s3
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	9a0080e7          	jalr	-1632(ra) # 80003828 <ilock>
    if(ip->type != T_DIR){
    80003e90:	04499783          	lh	a5,68(s3)
    80003e94:	f97793e3          	bne	a5,s7,80003e1a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e98:	000a8563          	beqz	s5,80003ea2 <namex+0xe6>
    80003e9c:	0004c783          	lbu	a5,0(s1)
    80003ea0:	d3cd                	beqz	a5,80003e42 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ea2:	865a                	mv	a2,s6
    80003ea4:	85d2                	mv	a1,s4
    80003ea6:	854e                	mv	a0,s3
    80003ea8:	00000097          	auipc	ra,0x0
    80003eac:	e64080e7          	jalr	-412(ra) # 80003d0c <dirlookup>
    80003eb0:	8caa                	mv	s9,a0
    80003eb2:	dd51                	beqz	a0,80003e4e <namex+0x92>
    iunlockput(ip);
    80003eb4:	854e                	mv	a0,s3
    80003eb6:	00000097          	auipc	ra,0x0
    80003eba:	bd4080e7          	jalr	-1068(ra) # 80003a8a <iunlockput>
    ip = next;
    80003ebe:	89e6                	mv	s3,s9
  while(*path == '/')
    80003ec0:	0004c783          	lbu	a5,0(s1)
    80003ec4:	05279763          	bne	a5,s2,80003f12 <namex+0x156>
    path++;
    80003ec8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003eca:	0004c783          	lbu	a5,0(s1)
    80003ece:	ff278de3          	beq	a5,s2,80003ec8 <namex+0x10c>
  if(*path == 0)
    80003ed2:	c79d                	beqz	a5,80003f00 <namex+0x144>
    path++;
    80003ed4:	85a6                	mv	a1,s1
  len = path - s;
    80003ed6:	8cda                	mv	s9,s6
    80003ed8:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80003eda:	01278963          	beq	a5,s2,80003eec <namex+0x130>
    80003ede:	dfbd                	beqz	a5,80003e5c <namex+0xa0>
    path++;
    80003ee0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003ee2:	0004c783          	lbu	a5,0(s1)
    80003ee6:	ff279ce3          	bne	a5,s2,80003ede <namex+0x122>
    80003eea:	bf8d                	j	80003e5c <namex+0xa0>
    memmove(name, s, len);
    80003eec:	2601                	sext.w	a2,a2
    80003eee:	8552                	mv	a0,s4
    80003ef0:	ffffd097          	auipc	ra,0xffffd
    80003ef4:	e2a080e7          	jalr	-470(ra) # 80000d1a <memmove>
    name[len] = 0;
    80003ef8:	9cd2                	add	s9,s9,s4
    80003efa:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003efe:	bf9d                	j	80003e74 <namex+0xb8>
  if(nameiparent){
    80003f00:	f20a83e3          	beqz	s5,80003e26 <namex+0x6a>
    iput(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	adc080e7          	jalr	-1316(ra) # 800039e2 <iput>
    return 0;
    80003f0e:	4981                	li	s3,0
    80003f10:	bf19                	j	80003e26 <namex+0x6a>
  if(*path == 0)
    80003f12:	d7fd                	beqz	a5,80003f00 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f14:	0004c783          	lbu	a5,0(s1)
    80003f18:	85a6                	mv	a1,s1
    80003f1a:	b7d1                	j	80003ede <namex+0x122>

0000000080003f1c <dirlink>:
{
    80003f1c:	7139                	addi	sp,sp,-64
    80003f1e:	fc06                	sd	ra,56(sp)
    80003f20:	f822                	sd	s0,48(sp)
    80003f22:	f426                	sd	s1,40(sp)
    80003f24:	f04a                	sd	s2,32(sp)
    80003f26:	ec4e                	sd	s3,24(sp)
    80003f28:	e852                	sd	s4,16(sp)
    80003f2a:	0080                	addi	s0,sp,64
    80003f2c:	892a                	mv	s2,a0
    80003f2e:	8a2e                	mv	s4,a1
    80003f30:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f32:	4601                	li	a2,0
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	dd8080e7          	jalr	-552(ra) # 80003d0c <dirlookup>
    80003f3c:	e93d                	bnez	a0,80003fb2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3e:	04c92483          	lw	s1,76(s2)
    80003f42:	c49d                	beqz	s1,80003f70 <dirlink+0x54>
    80003f44:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f46:	4741                	li	a4,16
    80003f48:	86a6                	mv	a3,s1
    80003f4a:	fc040613          	addi	a2,s0,-64
    80003f4e:	4581                	li	a1,0
    80003f50:	854a                	mv	a0,s2
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	b8a080e7          	jalr	-1142(ra) # 80003adc <readi>
    80003f5a:	47c1                	li	a5,16
    80003f5c:	06f51163          	bne	a0,a5,80003fbe <dirlink+0xa2>
    if(de.inum == 0)
    80003f60:	fc045783          	lhu	a5,-64(s0)
    80003f64:	c791                	beqz	a5,80003f70 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f66:	24c1                	addiw	s1,s1,16
    80003f68:	04c92783          	lw	a5,76(s2)
    80003f6c:	fcf4ede3          	bltu	s1,a5,80003f46 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f70:	4639                	li	a2,14
    80003f72:	85d2                	mv	a1,s4
    80003f74:	fc240513          	addi	a0,s0,-62
    80003f78:	ffffd097          	auipc	ra,0xffffd
    80003f7c:	e5a080e7          	jalr	-422(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80003f80:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f84:	4741                	li	a4,16
    80003f86:	86a6                	mv	a3,s1
    80003f88:	fc040613          	addi	a2,s0,-64
    80003f8c:	4581                	li	a1,0
    80003f8e:	854a                	mv	a0,s2
    80003f90:	00000097          	auipc	ra,0x0
    80003f94:	c44080e7          	jalr	-956(ra) # 80003bd4 <writei>
    80003f98:	872a                	mv	a4,a0
    80003f9a:	47c1                	li	a5,16
  return 0;
    80003f9c:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f9e:	02f71863          	bne	a4,a5,80003fce <dirlink+0xb2>
}
    80003fa2:	70e2                	ld	ra,56(sp)
    80003fa4:	7442                	ld	s0,48(sp)
    80003fa6:	74a2                	ld	s1,40(sp)
    80003fa8:	7902                	ld	s2,32(sp)
    80003faa:	69e2                	ld	s3,24(sp)
    80003fac:	6a42                	ld	s4,16(sp)
    80003fae:	6121                	addi	sp,sp,64
    80003fb0:	8082                	ret
    iput(ip);
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	a30080e7          	jalr	-1488(ra) # 800039e2 <iput>
    return -1;
    80003fba:	557d                	li	a0,-1
    80003fbc:	b7dd                	j	80003fa2 <dirlink+0x86>
      panic("dirlink read");
    80003fbe:	00005517          	auipc	a0,0x5
    80003fc2:	87a50513          	addi	a0,a0,-1926 # 80008838 <syscalls_str+0x1d0>
    80003fc6:	ffffc097          	auipc	ra,0xffffc
    80003fca:	564080e7          	jalr	1380(ra) # 8000052a <panic>
    panic("dirlink");
    80003fce:	00005517          	auipc	a0,0x5
    80003fd2:	97a50513          	addi	a0,a0,-1670 # 80008948 <syscalls_str+0x2e0>
    80003fd6:	ffffc097          	auipc	ra,0xffffc
    80003fda:	554080e7          	jalr	1364(ra) # 8000052a <panic>

0000000080003fde <namei>:

struct inode*
namei(char *path)
{
    80003fde:	1101                	addi	sp,sp,-32
    80003fe0:	ec06                	sd	ra,24(sp)
    80003fe2:	e822                	sd	s0,16(sp)
    80003fe4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fe6:	fe040613          	addi	a2,s0,-32
    80003fea:	4581                	li	a1,0
    80003fec:	00000097          	auipc	ra,0x0
    80003ff0:	dd0080e7          	jalr	-560(ra) # 80003dbc <namex>
}
    80003ff4:	60e2                	ld	ra,24(sp)
    80003ff6:	6442                	ld	s0,16(sp)
    80003ff8:	6105                	addi	sp,sp,32
    80003ffa:	8082                	ret

0000000080003ffc <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ffc:	1141                	addi	sp,sp,-16
    80003ffe:	e406                	sd	ra,8(sp)
    80004000:	e022                	sd	s0,0(sp)
    80004002:	0800                	addi	s0,sp,16
    80004004:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004006:	4585                	li	a1,1
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	db4080e7          	jalr	-588(ra) # 80003dbc <namex>
}
    80004010:	60a2                	ld	ra,8(sp)
    80004012:	6402                	ld	s0,0(sp)
    80004014:	0141                	addi	sp,sp,16
    80004016:	8082                	ret

0000000080004018 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	e426                	sd	s1,8(sp)
    80004020:	e04a                	sd	s2,0(sp)
    80004022:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004024:	0001d917          	auipc	s2,0x1d
    80004028:	44c90913          	addi	s2,s2,1100 # 80021470 <log>
    8000402c:	01892583          	lw	a1,24(s2)
    80004030:	02892503          	lw	a0,40(s2)
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	ff0080e7          	jalr	-16(ra) # 80003024 <bread>
    8000403c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000403e:	02c92683          	lw	a3,44(s2)
    80004042:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004044:	02d05863          	blez	a3,80004074 <write_head+0x5c>
    80004048:	0001d797          	auipc	a5,0x1d
    8000404c:	45878793          	addi	a5,a5,1112 # 800214a0 <log+0x30>
    80004050:	05c50713          	addi	a4,a0,92
    80004054:	36fd                	addiw	a3,a3,-1
    80004056:	02069613          	slli	a2,a3,0x20
    8000405a:	01e65693          	srli	a3,a2,0x1e
    8000405e:	0001d617          	auipc	a2,0x1d
    80004062:	44660613          	addi	a2,a2,1094 # 800214a4 <log+0x34>
    80004066:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004068:	4390                	lw	a2,0(a5)
    8000406a:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000406c:	0791                	addi	a5,a5,4
    8000406e:	0711                	addi	a4,a4,4
    80004070:	fed79ce3          	bne	a5,a3,80004068 <write_head+0x50>
  }
  bwrite(buf);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	0a0080e7          	jalr	160(ra) # 80003116 <bwrite>
  brelse(buf);
    8000407e:	8526                	mv	a0,s1
    80004080:	fffff097          	auipc	ra,0xfffff
    80004084:	0d4080e7          	jalr	212(ra) # 80003154 <brelse>
}
    80004088:	60e2                	ld	ra,24(sp)
    8000408a:	6442                	ld	s0,16(sp)
    8000408c:	64a2                	ld	s1,8(sp)
    8000408e:	6902                	ld	s2,0(sp)
    80004090:	6105                	addi	sp,sp,32
    80004092:	8082                	ret

0000000080004094 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004094:	0001d797          	auipc	a5,0x1d
    80004098:	4087a783          	lw	a5,1032(a5) # 8002149c <log+0x2c>
    8000409c:	0af05d63          	blez	a5,80004156 <install_trans+0xc2>
{
    800040a0:	7139                	addi	sp,sp,-64
    800040a2:	fc06                	sd	ra,56(sp)
    800040a4:	f822                	sd	s0,48(sp)
    800040a6:	f426                	sd	s1,40(sp)
    800040a8:	f04a                	sd	s2,32(sp)
    800040aa:	ec4e                	sd	s3,24(sp)
    800040ac:	e852                	sd	s4,16(sp)
    800040ae:	e456                	sd	s5,8(sp)
    800040b0:	e05a                	sd	s6,0(sp)
    800040b2:	0080                	addi	s0,sp,64
    800040b4:	8b2a                	mv	s6,a0
    800040b6:	0001da97          	auipc	s5,0x1d
    800040ba:	3eaa8a93          	addi	s5,s5,1002 # 800214a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040be:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040c0:	0001d997          	auipc	s3,0x1d
    800040c4:	3b098993          	addi	s3,s3,944 # 80021470 <log>
    800040c8:	a00d                	j	800040ea <install_trans+0x56>
    brelse(lbuf);
    800040ca:	854a                	mv	a0,s2
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	088080e7          	jalr	136(ra) # 80003154 <brelse>
    brelse(dbuf);
    800040d4:	8526                	mv	a0,s1
    800040d6:	fffff097          	auipc	ra,0xfffff
    800040da:	07e080e7          	jalr	126(ra) # 80003154 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040de:	2a05                	addiw	s4,s4,1
    800040e0:	0a91                	addi	s5,s5,4
    800040e2:	02c9a783          	lw	a5,44(s3)
    800040e6:	04fa5e63          	bge	s4,a5,80004142 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040ea:	0189a583          	lw	a1,24(s3)
    800040ee:	014585bb          	addw	a1,a1,s4
    800040f2:	2585                	addiw	a1,a1,1
    800040f4:	0289a503          	lw	a0,40(s3)
    800040f8:	fffff097          	auipc	ra,0xfffff
    800040fc:	f2c080e7          	jalr	-212(ra) # 80003024 <bread>
    80004100:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004102:	000aa583          	lw	a1,0(s5)
    80004106:	0289a503          	lw	a0,40(s3)
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	f1a080e7          	jalr	-230(ra) # 80003024 <bread>
    80004112:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004114:	40000613          	li	a2,1024
    80004118:	05890593          	addi	a1,s2,88
    8000411c:	05850513          	addi	a0,a0,88
    80004120:	ffffd097          	auipc	ra,0xffffd
    80004124:	bfa080e7          	jalr	-1030(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    80004128:	8526                	mv	a0,s1
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	fec080e7          	jalr	-20(ra) # 80003116 <bwrite>
    if(recovering == 0)
    80004132:	f80b1ce3          	bnez	s6,800040ca <install_trans+0x36>
      bunpin(dbuf);
    80004136:	8526                	mv	a0,s1
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	0f6080e7          	jalr	246(ra) # 8000322e <bunpin>
    80004140:	b769                	j	800040ca <install_trans+0x36>
}
    80004142:	70e2                	ld	ra,56(sp)
    80004144:	7442                	ld	s0,48(sp)
    80004146:	74a2                	ld	s1,40(sp)
    80004148:	7902                	ld	s2,32(sp)
    8000414a:	69e2                	ld	s3,24(sp)
    8000414c:	6a42                	ld	s4,16(sp)
    8000414e:	6aa2                	ld	s5,8(sp)
    80004150:	6b02                	ld	s6,0(sp)
    80004152:	6121                	addi	sp,sp,64
    80004154:	8082                	ret
    80004156:	8082                	ret

0000000080004158 <initlog>:
{
    80004158:	7179                	addi	sp,sp,-48
    8000415a:	f406                	sd	ra,40(sp)
    8000415c:	f022                	sd	s0,32(sp)
    8000415e:	ec26                	sd	s1,24(sp)
    80004160:	e84a                	sd	s2,16(sp)
    80004162:	e44e                	sd	s3,8(sp)
    80004164:	1800                	addi	s0,sp,48
    80004166:	892a                	mv	s2,a0
    80004168:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000416a:	0001d497          	auipc	s1,0x1d
    8000416e:	30648493          	addi	s1,s1,774 # 80021470 <log>
    80004172:	00004597          	auipc	a1,0x4
    80004176:	6d658593          	addi	a1,a1,1750 # 80008848 <syscalls_str+0x1e0>
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffd097          	auipc	ra,0xffffd
    80004180:	9b6080e7          	jalr	-1610(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004184:	0149a583          	lw	a1,20(s3)
    80004188:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000418a:	0109a783          	lw	a5,16(s3)
    8000418e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004190:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004194:	854a                	mv	a0,s2
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	e8e080e7          	jalr	-370(ra) # 80003024 <bread>
  log.lh.n = lh->n;
    8000419e:	4d34                	lw	a3,88(a0)
    800041a0:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041a2:	02d05663          	blez	a3,800041ce <initlog+0x76>
    800041a6:	05c50793          	addi	a5,a0,92
    800041aa:	0001d717          	auipc	a4,0x1d
    800041ae:	2f670713          	addi	a4,a4,758 # 800214a0 <log+0x30>
    800041b2:	36fd                	addiw	a3,a3,-1
    800041b4:	02069613          	slli	a2,a3,0x20
    800041b8:	01e65693          	srli	a3,a2,0x1e
    800041bc:	06050613          	addi	a2,a0,96
    800041c0:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800041c2:	4390                	lw	a2,0(a5)
    800041c4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041c6:	0791                	addi	a5,a5,4
    800041c8:	0711                	addi	a4,a4,4
    800041ca:	fed79ce3          	bne	a5,a3,800041c2 <initlog+0x6a>
  brelse(buf);
    800041ce:	fffff097          	auipc	ra,0xfffff
    800041d2:	f86080e7          	jalr	-122(ra) # 80003154 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800041d6:	4505                	li	a0,1
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	ebc080e7          	jalr	-324(ra) # 80004094 <install_trans>
  log.lh.n = 0;
    800041e0:	0001d797          	auipc	a5,0x1d
    800041e4:	2a07ae23          	sw	zero,700(a5) # 8002149c <log+0x2c>
  write_head(); // clear the log
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	e30080e7          	jalr	-464(ra) # 80004018 <write_head>
}
    800041f0:	70a2                	ld	ra,40(sp)
    800041f2:	7402                	ld	s0,32(sp)
    800041f4:	64e2                	ld	s1,24(sp)
    800041f6:	6942                	ld	s2,16(sp)
    800041f8:	69a2                	ld	s3,8(sp)
    800041fa:	6145                	addi	sp,sp,48
    800041fc:	8082                	ret

00000000800041fe <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041fe:	1101                	addi	sp,sp,-32
    80004200:	ec06                	sd	ra,24(sp)
    80004202:	e822                	sd	s0,16(sp)
    80004204:	e426                	sd	s1,8(sp)
    80004206:	e04a                	sd	s2,0(sp)
    80004208:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000420a:	0001d517          	auipc	a0,0x1d
    8000420e:	26650513          	addi	a0,a0,614 # 80021470 <log>
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	9b0080e7          	jalr	-1616(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    8000421a:	0001d497          	auipc	s1,0x1d
    8000421e:	25648493          	addi	s1,s1,598 # 80021470 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004222:	4979                	li	s2,30
    80004224:	a039                	j	80004232 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004226:	85a6                	mv	a1,s1
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffe097          	auipc	ra,0xffffe
    8000422e:	e82080e7          	jalr	-382(ra) # 800020ac <sleep>
    if(log.committing){
    80004232:	50dc                	lw	a5,36(s1)
    80004234:	fbed                	bnez	a5,80004226 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004236:	509c                	lw	a5,32(s1)
    80004238:	0017871b          	addiw	a4,a5,1
    8000423c:	0007069b          	sext.w	a3,a4
    80004240:	0027179b          	slliw	a5,a4,0x2
    80004244:	9fb9                	addw	a5,a5,a4
    80004246:	0017979b          	slliw	a5,a5,0x1
    8000424a:	54d8                	lw	a4,44(s1)
    8000424c:	9fb9                	addw	a5,a5,a4
    8000424e:	00f95963          	bge	s2,a5,80004260 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004252:	85a6                	mv	a1,s1
    80004254:	8526                	mv	a0,s1
    80004256:	ffffe097          	auipc	ra,0xffffe
    8000425a:	e56080e7          	jalr	-426(ra) # 800020ac <sleep>
    8000425e:	bfd1                	j	80004232 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004260:	0001d517          	auipc	a0,0x1d
    80004264:	21050513          	addi	a0,a0,528 # 80021470 <log>
    80004268:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	a0c080e7          	jalr	-1524(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004272:	60e2                	ld	ra,24(sp)
    80004274:	6442                	ld	s0,16(sp)
    80004276:	64a2                	ld	s1,8(sp)
    80004278:	6902                	ld	s2,0(sp)
    8000427a:	6105                	addi	sp,sp,32
    8000427c:	8082                	ret

000000008000427e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000427e:	7139                	addi	sp,sp,-64
    80004280:	fc06                	sd	ra,56(sp)
    80004282:	f822                	sd	s0,48(sp)
    80004284:	f426                	sd	s1,40(sp)
    80004286:	f04a                	sd	s2,32(sp)
    80004288:	ec4e                	sd	s3,24(sp)
    8000428a:	e852                	sd	s4,16(sp)
    8000428c:	e456                	sd	s5,8(sp)
    8000428e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004290:	0001d497          	auipc	s1,0x1d
    80004294:	1e048493          	addi	s1,s1,480 # 80021470 <log>
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	928080e7          	jalr	-1752(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    800042a2:	509c                	lw	a5,32(s1)
    800042a4:	37fd                	addiw	a5,a5,-1
    800042a6:	0007891b          	sext.w	s2,a5
    800042aa:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042ac:	50dc                	lw	a5,36(s1)
    800042ae:	e7b9                	bnez	a5,800042fc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042b0:	04091e63          	bnez	s2,8000430c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800042b4:	0001d497          	auipc	s1,0x1d
    800042b8:	1bc48493          	addi	s1,s1,444 # 80021470 <log>
    800042bc:	4785                	li	a5,1
    800042be:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042c0:	8526                	mv	a0,s1
    800042c2:	ffffd097          	auipc	ra,0xffffd
    800042c6:	9b4080e7          	jalr	-1612(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042ca:	54dc                	lw	a5,44(s1)
    800042cc:	06f04763          	bgtz	a5,8000433a <end_op+0xbc>
    acquire(&log.lock);
    800042d0:	0001d497          	auipc	s1,0x1d
    800042d4:	1a048493          	addi	s1,s1,416 # 80021470 <log>
    800042d8:	8526                	mv	a0,s1
    800042da:	ffffd097          	auipc	ra,0xffffd
    800042de:	8e8080e7          	jalr	-1816(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800042e2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042e6:	8526                	mv	a0,s1
    800042e8:	ffffe097          	auipc	ra,0xffffe
    800042ec:	f50080e7          	jalr	-176(ra) # 80002238 <wakeup>
    release(&log.lock);
    800042f0:	8526                	mv	a0,s1
    800042f2:	ffffd097          	auipc	ra,0xffffd
    800042f6:	984080e7          	jalr	-1660(ra) # 80000c76 <release>
}
    800042fa:	a03d                	j	80004328 <end_op+0xaa>
    panic("log.committing");
    800042fc:	00004517          	auipc	a0,0x4
    80004300:	55450513          	addi	a0,a0,1364 # 80008850 <syscalls_str+0x1e8>
    80004304:	ffffc097          	auipc	ra,0xffffc
    80004308:	226080e7          	jalr	550(ra) # 8000052a <panic>
    wakeup(&log);
    8000430c:	0001d497          	auipc	s1,0x1d
    80004310:	16448493          	addi	s1,s1,356 # 80021470 <log>
    80004314:	8526                	mv	a0,s1
    80004316:	ffffe097          	auipc	ra,0xffffe
    8000431a:	f22080e7          	jalr	-222(ra) # 80002238 <wakeup>
  release(&log.lock);
    8000431e:	8526                	mv	a0,s1
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	956080e7          	jalr	-1706(ra) # 80000c76 <release>
}
    80004328:	70e2                	ld	ra,56(sp)
    8000432a:	7442                	ld	s0,48(sp)
    8000432c:	74a2                	ld	s1,40(sp)
    8000432e:	7902                	ld	s2,32(sp)
    80004330:	69e2                	ld	s3,24(sp)
    80004332:	6a42                	ld	s4,16(sp)
    80004334:	6aa2                	ld	s5,8(sp)
    80004336:	6121                	addi	sp,sp,64
    80004338:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000433a:	0001da97          	auipc	s5,0x1d
    8000433e:	166a8a93          	addi	s5,s5,358 # 800214a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004342:	0001da17          	auipc	s4,0x1d
    80004346:	12ea0a13          	addi	s4,s4,302 # 80021470 <log>
    8000434a:	018a2583          	lw	a1,24(s4)
    8000434e:	012585bb          	addw	a1,a1,s2
    80004352:	2585                	addiw	a1,a1,1
    80004354:	028a2503          	lw	a0,40(s4)
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	ccc080e7          	jalr	-820(ra) # 80003024 <bread>
    80004360:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004362:	000aa583          	lw	a1,0(s5)
    80004366:	028a2503          	lw	a0,40(s4)
    8000436a:	fffff097          	auipc	ra,0xfffff
    8000436e:	cba080e7          	jalr	-838(ra) # 80003024 <bread>
    80004372:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004374:	40000613          	li	a2,1024
    80004378:	05850593          	addi	a1,a0,88
    8000437c:	05848513          	addi	a0,s1,88
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	99a080e7          	jalr	-1638(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    80004388:	8526                	mv	a0,s1
    8000438a:	fffff097          	auipc	ra,0xfffff
    8000438e:	d8c080e7          	jalr	-628(ra) # 80003116 <bwrite>
    brelse(from);
    80004392:	854e                	mv	a0,s3
    80004394:	fffff097          	auipc	ra,0xfffff
    80004398:	dc0080e7          	jalr	-576(ra) # 80003154 <brelse>
    brelse(to);
    8000439c:	8526                	mv	a0,s1
    8000439e:	fffff097          	auipc	ra,0xfffff
    800043a2:	db6080e7          	jalr	-586(ra) # 80003154 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a6:	2905                	addiw	s2,s2,1
    800043a8:	0a91                	addi	s5,s5,4
    800043aa:	02ca2783          	lw	a5,44(s4)
    800043ae:	f8f94ee3          	blt	s2,a5,8000434a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043b2:	00000097          	auipc	ra,0x0
    800043b6:	c66080e7          	jalr	-922(ra) # 80004018 <write_head>
    install_trans(0); // Now install writes to home locations
    800043ba:	4501                	li	a0,0
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	cd8080e7          	jalr	-808(ra) # 80004094 <install_trans>
    log.lh.n = 0;
    800043c4:	0001d797          	auipc	a5,0x1d
    800043c8:	0c07ac23          	sw	zero,216(a5) # 8002149c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	c4c080e7          	jalr	-948(ra) # 80004018 <write_head>
    800043d4:	bdf5                	j	800042d0 <end_op+0x52>

00000000800043d6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043d6:	1101                	addi	sp,sp,-32
    800043d8:	ec06                	sd	ra,24(sp)
    800043da:	e822                	sd	s0,16(sp)
    800043dc:	e426                	sd	s1,8(sp)
    800043de:	e04a                	sd	s2,0(sp)
    800043e0:	1000                	addi	s0,sp,32
    800043e2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800043e4:	0001d917          	auipc	s2,0x1d
    800043e8:	08c90913          	addi	s2,s2,140 # 80021470 <log>
    800043ec:	854a                	mv	a0,s2
    800043ee:	ffffc097          	auipc	ra,0xffffc
    800043f2:	7d4080e7          	jalr	2004(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043f6:	02c92603          	lw	a2,44(s2)
    800043fa:	47f5                	li	a5,29
    800043fc:	06c7c563          	blt	a5,a2,80004466 <log_write+0x90>
    80004400:	0001d797          	auipc	a5,0x1d
    80004404:	08c7a783          	lw	a5,140(a5) # 8002148c <log+0x1c>
    80004408:	37fd                	addiw	a5,a5,-1
    8000440a:	04f65e63          	bge	a2,a5,80004466 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000440e:	0001d797          	auipc	a5,0x1d
    80004412:	0827a783          	lw	a5,130(a5) # 80021490 <log+0x20>
    80004416:	06f05063          	blez	a5,80004476 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000441a:	4781                	li	a5,0
    8000441c:	06c05563          	blez	a2,80004486 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004420:	44cc                	lw	a1,12(s1)
    80004422:	0001d717          	auipc	a4,0x1d
    80004426:	07e70713          	addi	a4,a4,126 # 800214a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000442a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000442c:	4314                	lw	a3,0(a4)
    8000442e:	04b68c63          	beq	a3,a1,80004486 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004432:	2785                	addiw	a5,a5,1
    80004434:	0711                	addi	a4,a4,4
    80004436:	fef61be3          	bne	a2,a5,8000442c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000443a:	0621                	addi	a2,a2,8
    8000443c:	060a                	slli	a2,a2,0x2
    8000443e:	0001d797          	auipc	a5,0x1d
    80004442:	03278793          	addi	a5,a5,50 # 80021470 <log>
    80004446:	963e                	add	a2,a2,a5
    80004448:	44dc                	lw	a5,12(s1)
    8000444a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000444c:	8526                	mv	a0,s1
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	da4080e7          	jalr	-604(ra) # 800031f2 <bpin>
    log.lh.n++;
    80004456:	0001d717          	auipc	a4,0x1d
    8000445a:	01a70713          	addi	a4,a4,26 # 80021470 <log>
    8000445e:	575c                	lw	a5,44(a4)
    80004460:	2785                	addiw	a5,a5,1
    80004462:	d75c                	sw	a5,44(a4)
    80004464:	a835                	j	800044a0 <log_write+0xca>
    panic("too big a transaction");
    80004466:	00004517          	auipc	a0,0x4
    8000446a:	3fa50513          	addi	a0,a0,1018 # 80008860 <syscalls_str+0x1f8>
    8000446e:	ffffc097          	auipc	ra,0xffffc
    80004472:	0bc080e7          	jalr	188(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    80004476:	00004517          	auipc	a0,0x4
    8000447a:	40250513          	addi	a0,a0,1026 # 80008878 <syscalls_str+0x210>
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	0ac080e7          	jalr	172(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    80004486:	00878713          	addi	a4,a5,8
    8000448a:	00271693          	slli	a3,a4,0x2
    8000448e:	0001d717          	auipc	a4,0x1d
    80004492:	fe270713          	addi	a4,a4,-30 # 80021470 <log>
    80004496:	9736                	add	a4,a4,a3
    80004498:	44d4                	lw	a3,12(s1)
    8000449a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000449c:	faf608e3          	beq	a2,a5,8000444c <log_write+0x76>
  }
  release(&log.lock);
    800044a0:	0001d517          	auipc	a0,0x1d
    800044a4:	fd050513          	addi	a0,a0,-48 # 80021470 <log>
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	7ce080e7          	jalr	1998(ra) # 80000c76 <release>
}
    800044b0:	60e2                	ld	ra,24(sp)
    800044b2:	6442                	ld	s0,16(sp)
    800044b4:	64a2                	ld	s1,8(sp)
    800044b6:	6902                	ld	s2,0(sp)
    800044b8:	6105                	addi	sp,sp,32
    800044ba:	8082                	ret

00000000800044bc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044bc:	1101                	addi	sp,sp,-32
    800044be:	ec06                	sd	ra,24(sp)
    800044c0:	e822                	sd	s0,16(sp)
    800044c2:	e426                	sd	s1,8(sp)
    800044c4:	e04a                	sd	s2,0(sp)
    800044c6:	1000                	addi	s0,sp,32
    800044c8:	84aa                	mv	s1,a0
    800044ca:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044cc:	00004597          	auipc	a1,0x4
    800044d0:	3cc58593          	addi	a1,a1,972 # 80008898 <syscalls_str+0x230>
    800044d4:	0521                	addi	a0,a0,8
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	65c080e7          	jalr	1628(ra) # 80000b32 <initlock>
  lk->name = name;
    800044de:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e6:	0204a423          	sw	zero,40(s1)
}
    800044ea:	60e2                	ld	ra,24(sp)
    800044ec:	6442                	ld	s0,16(sp)
    800044ee:	64a2                	ld	s1,8(sp)
    800044f0:	6902                	ld	s2,0(sp)
    800044f2:	6105                	addi	sp,sp,32
    800044f4:	8082                	ret

00000000800044f6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044f6:	1101                	addi	sp,sp,-32
    800044f8:	ec06                	sd	ra,24(sp)
    800044fa:	e822                	sd	s0,16(sp)
    800044fc:	e426                	sd	s1,8(sp)
    800044fe:	e04a                	sd	s2,0(sp)
    80004500:	1000                	addi	s0,sp,32
    80004502:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004504:	00850913          	addi	s2,a0,8
    80004508:	854a                	mv	a0,s2
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	6b8080e7          	jalr	1720(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    80004512:	409c                	lw	a5,0(s1)
    80004514:	cb89                	beqz	a5,80004526 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004516:	85ca                	mv	a1,s2
    80004518:	8526                	mv	a0,s1
    8000451a:	ffffe097          	auipc	ra,0xffffe
    8000451e:	b92080e7          	jalr	-1134(ra) # 800020ac <sleep>
  while (lk->locked) {
    80004522:	409c                	lw	a5,0(s1)
    80004524:	fbed                	bnez	a5,80004516 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004526:	4785                	li	a5,1
    80004528:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000452a:	ffffd097          	auipc	ra,0xffffd
    8000452e:	468080e7          	jalr	1128(ra) # 80001992 <myproc>
    80004532:	591c                	lw	a5,48(a0)
    80004534:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004536:	854a                	mv	a0,s2
    80004538:	ffffc097          	auipc	ra,0xffffc
    8000453c:	73e080e7          	jalr	1854(ra) # 80000c76 <release>
}
    80004540:	60e2                	ld	ra,24(sp)
    80004542:	6442                	ld	s0,16(sp)
    80004544:	64a2                	ld	s1,8(sp)
    80004546:	6902                	ld	s2,0(sp)
    80004548:	6105                	addi	sp,sp,32
    8000454a:	8082                	ret

000000008000454c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000454c:	1101                	addi	sp,sp,-32
    8000454e:	ec06                	sd	ra,24(sp)
    80004550:	e822                	sd	s0,16(sp)
    80004552:	e426                	sd	s1,8(sp)
    80004554:	e04a                	sd	s2,0(sp)
    80004556:	1000                	addi	s0,sp,32
    80004558:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000455a:	00850913          	addi	s2,a0,8
    8000455e:	854a                	mv	a0,s2
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	662080e7          	jalr	1634(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    80004568:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000456c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004570:	8526                	mv	a0,s1
    80004572:	ffffe097          	auipc	ra,0xffffe
    80004576:	cc6080e7          	jalr	-826(ra) # 80002238 <wakeup>
  release(&lk->lk);
    8000457a:	854a                	mv	a0,s2
    8000457c:	ffffc097          	auipc	ra,0xffffc
    80004580:	6fa080e7          	jalr	1786(ra) # 80000c76 <release>
}
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6902                	ld	s2,0(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret

0000000080004590 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004590:	7179                	addi	sp,sp,-48
    80004592:	f406                	sd	ra,40(sp)
    80004594:	f022                	sd	s0,32(sp)
    80004596:	ec26                	sd	s1,24(sp)
    80004598:	e84a                	sd	s2,16(sp)
    8000459a:	e44e                	sd	s3,8(sp)
    8000459c:	1800                	addi	s0,sp,48
    8000459e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045a0:	00850913          	addi	s2,a0,8
    800045a4:	854a                	mv	a0,s2
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	61c080e7          	jalr	1564(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ae:	409c                	lw	a5,0(s1)
    800045b0:	ef99                	bnez	a5,800045ce <holdingsleep+0x3e>
    800045b2:	4481                	li	s1,0
  release(&lk->lk);
    800045b4:	854a                	mv	a0,s2
    800045b6:	ffffc097          	auipc	ra,0xffffc
    800045ba:	6c0080e7          	jalr	1728(ra) # 80000c76 <release>
  return r;
}
    800045be:	8526                	mv	a0,s1
    800045c0:	70a2                	ld	ra,40(sp)
    800045c2:	7402                	ld	s0,32(sp)
    800045c4:	64e2                	ld	s1,24(sp)
    800045c6:	6942                	ld	s2,16(sp)
    800045c8:	69a2                	ld	s3,8(sp)
    800045ca:	6145                	addi	sp,sp,48
    800045cc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045ce:	0284a983          	lw	s3,40(s1)
    800045d2:	ffffd097          	auipc	ra,0xffffd
    800045d6:	3c0080e7          	jalr	960(ra) # 80001992 <myproc>
    800045da:	5904                	lw	s1,48(a0)
    800045dc:	413484b3          	sub	s1,s1,s3
    800045e0:	0014b493          	seqz	s1,s1
    800045e4:	bfc1                	j	800045b4 <holdingsleep+0x24>

00000000800045e6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045e6:	1141                	addi	sp,sp,-16
    800045e8:	e406                	sd	ra,8(sp)
    800045ea:	e022                	sd	s0,0(sp)
    800045ec:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045ee:	00004597          	auipc	a1,0x4
    800045f2:	2ba58593          	addi	a1,a1,698 # 800088a8 <syscalls_str+0x240>
    800045f6:	0001d517          	auipc	a0,0x1d
    800045fa:	fc250513          	addi	a0,a0,-62 # 800215b8 <ftable>
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	534080e7          	jalr	1332(ra) # 80000b32 <initlock>
}
    80004606:	60a2                	ld	ra,8(sp)
    80004608:	6402                	ld	s0,0(sp)
    8000460a:	0141                	addi	sp,sp,16
    8000460c:	8082                	ret

000000008000460e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000460e:	1101                	addi	sp,sp,-32
    80004610:	ec06                	sd	ra,24(sp)
    80004612:	e822                	sd	s0,16(sp)
    80004614:	e426                	sd	s1,8(sp)
    80004616:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004618:	0001d517          	auipc	a0,0x1d
    8000461c:	fa050513          	addi	a0,a0,-96 # 800215b8 <ftable>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	5a2080e7          	jalr	1442(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004628:	0001d497          	auipc	s1,0x1d
    8000462c:	fa848493          	addi	s1,s1,-88 # 800215d0 <ftable+0x18>
    80004630:	0001e717          	auipc	a4,0x1e
    80004634:	f4070713          	addi	a4,a4,-192 # 80022570 <ftable+0xfb8>
    if(f->ref == 0){
    80004638:	40dc                	lw	a5,4(s1)
    8000463a:	cf99                	beqz	a5,80004658 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000463c:	02848493          	addi	s1,s1,40
    80004640:	fee49ce3          	bne	s1,a4,80004638 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004644:	0001d517          	auipc	a0,0x1d
    80004648:	f7450513          	addi	a0,a0,-140 # 800215b8 <ftable>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	62a080e7          	jalr	1578(ra) # 80000c76 <release>
  return 0;
    80004654:	4481                	li	s1,0
    80004656:	a819                	j	8000466c <filealloc+0x5e>
      f->ref = 1;
    80004658:	4785                	li	a5,1
    8000465a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000465c:	0001d517          	auipc	a0,0x1d
    80004660:	f5c50513          	addi	a0,a0,-164 # 800215b8 <ftable>
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	612080e7          	jalr	1554(ra) # 80000c76 <release>
}
    8000466c:	8526                	mv	a0,s1
    8000466e:	60e2                	ld	ra,24(sp)
    80004670:	6442                	ld	s0,16(sp)
    80004672:	64a2                	ld	s1,8(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret

0000000080004678 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	1000                	addi	s0,sp,32
    80004682:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004684:	0001d517          	auipc	a0,0x1d
    80004688:	f3450513          	addi	a0,a0,-204 # 800215b8 <ftable>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	536080e7          	jalr	1334(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004694:	40dc                	lw	a5,4(s1)
    80004696:	02f05263          	blez	a5,800046ba <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000469a:	2785                	addiw	a5,a5,1
    8000469c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	f1a50513          	addi	a0,a0,-230 # 800215b8 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	5d0080e7          	jalr	1488(ra) # 80000c76 <release>
  return f;
}
    800046ae:	8526                	mv	a0,s1
    800046b0:	60e2                	ld	ra,24(sp)
    800046b2:	6442                	ld	s0,16(sp)
    800046b4:	64a2                	ld	s1,8(sp)
    800046b6:	6105                	addi	sp,sp,32
    800046b8:	8082                	ret
    panic("filedup");
    800046ba:	00004517          	auipc	a0,0x4
    800046be:	1f650513          	addi	a0,a0,502 # 800088b0 <syscalls_str+0x248>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	e68080e7          	jalr	-408(ra) # 8000052a <panic>

00000000800046ca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046ca:	7139                	addi	sp,sp,-64
    800046cc:	fc06                	sd	ra,56(sp)
    800046ce:	f822                	sd	s0,48(sp)
    800046d0:	f426                	sd	s1,40(sp)
    800046d2:	f04a                	sd	s2,32(sp)
    800046d4:	ec4e                	sd	s3,24(sp)
    800046d6:	e852                	sd	s4,16(sp)
    800046d8:	e456                	sd	s5,8(sp)
    800046da:	0080                	addi	s0,sp,64
    800046dc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046de:	0001d517          	auipc	a0,0x1d
    800046e2:	eda50513          	addi	a0,a0,-294 # 800215b8 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	4dc080e7          	jalr	1244(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800046ee:	40dc                	lw	a5,4(s1)
    800046f0:	06f05163          	blez	a5,80004752 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046f4:	37fd                	addiw	a5,a5,-1
    800046f6:	0007871b          	sext.w	a4,a5
    800046fa:	c0dc                	sw	a5,4(s1)
    800046fc:	06e04363          	bgtz	a4,80004762 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004700:	0004a903          	lw	s2,0(s1)
    80004704:	0094ca83          	lbu	s5,9(s1)
    80004708:	0104ba03          	ld	s4,16(s1)
    8000470c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004710:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004714:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004718:	0001d517          	auipc	a0,0x1d
    8000471c:	ea050513          	addi	a0,a0,-352 # 800215b8 <ftable>
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	556080e7          	jalr	1366(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    80004728:	4785                	li	a5,1
    8000472a:	04f90d63          	beq	s2,a5,80004784 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000472e:	3979                	addiw	s2,s2,-2
    80004730:	4785                	li	a5,1
    80004732:	0527e063          	bltu	a5,s2,80004772 <fileclose+0xa8>
    begin_op();
    80004736:	00000097          	auipc	ra,0x0
    8000473a:	ac8080e7          	jalr	-1336(ra) # 800041fe <begin_op>
    iput(ff.ip);
    8000473e:	854e                	mv	a0,s3
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	2a2080e7          	jalr	674(ra) # 800039e2 <iput>
    end_op();
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	b36080e7          	jalr	-1226(ra) # 8000427e <end_op>
    80004750:	a00d                	j	80004772 <fileclose+0xa8>
    panic("fileclose");
    80004752:	00004517          	auipc	a0,0x4
    80004756:	16650513          	addi	a0,a0,358 # 800088b8 <syscalls_str+0x250>
    8000475a:	ffffc097          	auipc	ra,0xffffc
    8000475e:	dd0080e7          	jalr	-560(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004762:	0001d517          	auipc	a0,0x1d
    80004766:	e5650513          	addi	a0,a0,-426 # 800215b8 <ftable>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	50c080e7          	jalr	1292(ra) # 80000c76 <release>
  }
}
    80004772:	70e2                	ld	ra,56(sp)
    80004774:	7442                	ld	s0,48(sp)
    80004776:	74a2                	ld	s1,40(sp)
    80004778:	7902                	ld	s2,32(sp)
    8000477a:	69e2                	ld	s3,24(sp)
    8000477c:	6a42                	ld	s4,16(sp)
    8000477e:	6aa2                	ld	s5,8(sp)
    80004780:	6121                	addi	sp,sp,64
    80004782:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004784:	85d6                	mv	a1,s5
    80004786:	8552                	mv	a0,s4
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	34c080e7          	jalr	844(ra) # 80004ad4 <pipeclose>
    80004790:	b7cd                	j	80004772 <fileclose+0xa8>

0000000080004792 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004792:	715d                	addi	sp,sp,-80
    80004794:	e486                	sd	ra,72(sp)
    80004796:	e0a2                	sd	s0,64(sp)
    80004798:	fc26                	sd	s1,56(sp)
    8000479a:	f84a                	sd	s2,48(sp)
    8000479c:	f44e                	sd	s3,40(sp)
    8000479e:	0880                	addi	s0,sp,80
    800047a0:	84aa                	mv	s1,a0
    800047a2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047a4:	ffffd097          	auipc	ra,0xffffd
    800047a8:	1ee080e7          	jalr	494(ra) # 80001992 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047ac:	409c                	lw	a5,0(s1)
    800047ae:	37f9                	addiw	a5,a5,-2
    800047b0:	4705                	li	a4,1
    800047b2:	04f76763          	bltu	a4,a5,80004800 <filestat+0x6e>
    800047b6:	892a                	mv	s2,a0
    ilock(f->ip);
    800047b8:	6c88                	ld	a0,24(s1)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	06e080e7          	jalr	110(ra) # 80003828 <ilock>
    stati(f->ip, &st);
    800047c2:	fb840593          	addi	a1,s0,-72
    800047c6:	6c88                	ld	a0,24(s1)
    800047c8:	fffff097          	auipc	ra,0xfffff
    800047cc:	2ea080e7          	jalr	746(ra) # 80003ab2 <stati>
    iunlock(f->ip);
    800047d0:	6c88                	ld	a0,24(s1)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	118080e7          	jalr	280(ra) # 800038ea <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047da:	46e1                	li	a3,24
    800047dc:	fb840613          	addi	a2,s0,-72
    800047e0:	85ce                	mv	a1,s3
    800047e2:	05093503          	ld	a0,80(s2)
    800047e6:	ffffd097          	auipc	ra,0xffffd
    800047ea:	e58080e7          	jalr	-424(ra) # 8000163e <copyout>
    800047ee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047f2:	60a6                	ld	ra,72(sp)
    800047f4:	6406                	ld	s0,64(sp)
    800047f6:	74e2                	ld	s1,56(sp)
    800047f8:	7942                	ld	s2,48(sp)
    800047fa:	79a2                	ld	s3,40(sp)
    800047fc:	6161                	addi	sp,sp,80
    800047fe:	8082                	ret
  return -1;
    80004800:	557d                	li	a0,-1
    80004802:	bfc5                	j	800047f2 <filestat+0x60>

0000000080004804 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004804:	7179                	addi	sp,sp,-48
    80004806:	f406                	sd	ra,40(sp)
    80004808:	f022                	sd	s0,32(sp)
    8000480a:	ec26                	sd	s1,24(sp)
    8000480c:	e84a                	sd	s2,16(sp)
    8000480e:	e44e                	sd	s3,8(sp)
    80004810:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004812:	00854783          	lbu	a5,8(a0)
    80004816:	c3d5                	beqz	a5,800048ba <fileread+0xb6>
    80004818:	84aa                	mv	s1,a0
    8000481a:	89ae                	mv	s3,a1
    8000481c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000481e:	411c                	lw	a5,0(a0)
    80004820:	4705                	li	a4,1
    80004822:	04e78963          	beq	a5,a4,80004874 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004826:	470d                	li	a4,3
    80004828:	04e78d63          	beq	a5,a4,80004882 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000482c:	4709                	li	a4,2
    8000482e:	06e79e63          	bne	a5,a4,800048aa <fileread+0xa6>
    ilock(f->ip);
    80004832:	6d08                	ld	a0,24(a0)
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	ff4080e7          	jalr	-12(ra) # 80003828 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000483c:	874a                	mv	a4,s2
    8000483e:	5094                	lw	a3,32(s1)
    80004840:	864e                	mv	a2,s3
    80004842:	4585                	li	a1,1
    80004844:	6c88                	ld	a0,24(s1)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	296080e7          	jalr	662(ra) # 80003adc <readi>
    8000484e:	892a                	mv	s2,a0
    80004850:	00a05563          	blez	a0,8000485a <fileread+0x56>
      f->off += r;
    80004854:	509c                	lw	a5,32(s1)
    80004856:	9fa9                	addw	a5,a5,a0
    80004858:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000485a:	6c88                	ld	a0,24(s1)
    8000485c:	fffff097          	auipc	ra,0xfffff
    80004860:	08e080e7          	jalr	142(ra) # 800038ea <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004864:	854a                	mv	a0,s2
    80004866:	70a2                	ld	ra,40(sp)
    80004868:	7402                	ld	s0,32(sp)
    8000486a:	64e2                	ld	s1,24(sp)
    8000486c:	6942                	ld	s2,16(sp)
    8000486e:	69a2                	ld	s3,8(sp)
    80004870:	6145                	addi	sp,sp,48
    80004872:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004874:	6908                	ld	a0,16(a0)
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	3c0080e7          	jalr	960(ra) # 80004c36 <piperead>
    8000487e:	892a                	mv	s2,a0
    80004880:	b7d5                	j	80004864 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004882:	02451783          	lh	a5,36(a0)
    80004886:	03079693          	slli	a3,a5,0x30
    8000488a:	92c1                	srli	a3,a3,0x30
    8000488c:	4725                	li	a4,9
    8000488e:	02d76863          	bltu	a4,a3,800048be <fileread+0xba>
    80004892:	0792                	slli	a5,a5,0x4
    80004894:	0001d717          	auipc	a4,0x1d
    80004898:	c8470713          	addi	a4,a4,-892 # 80021518 <devsw>
    8000489c:	97ba                	add	a5,a5,a4
    8000489e:	639c                	ld	a5,0(a5)
    800048a0:	c38d                	beqz	a5,800048c2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048a2:	4505                	li	a0,1
    800048a4:	9782                	jalr	a5
    800048a6:	892a                	mv	s2,a0
    800048a8:	bf75                	j	80004864 <fileread+0x60>
    panic("fileread");
    800048aa:	00004517          	auipc	a0,0x4
    800048ae:	01e50513          	addi	a0,a0,30 # 800088c8 <syscalls_str+0x260>
    800048b2:	ffffc097          	auipc	ra,0xffffc
    800048b6:	c78080e7          	jalr	-904(ra) # 8000052a <panic>
    return -1;
    800048ba:	597d                	li	s2,-1
    800048bc:	b765                	j	80004864 <fileread+0x60>
      return -1;
    800048be:	597d                	li	s2,-1
    800048c0:	b755                	j	80004864 <fileread+0x60>
    800048c2:	597d                	li	s2,-1
    800048c4:	b745                	j	80004864 <fileread+0x60>

00000000800048c6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800048c6:	715d                	addi	sp,sp,-80
    800048c8:	e486                	sd	ra,72(sp)
    800048ca:	e0a2                	sd	s0,64(sp)
    800048cc:	fc26                	sd	s1,56(sp)
    800048ce:	f84a                	sd	s2,48(sp)
    800048d0:	f44e                	sd	s3,40(sp)
    800048d2:	f052                	sd	s4,32(sp)
    800048d4:	ec56                	sd	s5,24(sp)
    800048d6:	e85a                	sd	s6,16(sp)
    800048d8:	e45e                	sd	s7,8(sp)
    800048da:	e062                	sd	s8,0(sp)
    800048dc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800048de:	00954783          	lbu	a5,9(a0)
    800048e2:	10078663          	beqz	a5,800049ee <filewrite+0x128>
    800048e6:	892a                	mv	s2,a0
    800048e8:	8aae                	mv	s5,a1
    800048ea:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048ec:	411c                	lw	a5,0(a0)
    800048ee:	4705                	li	a4,1
    800048f0:	02e78263          	beq	a5,a4,80004914 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048f4:	470d                	li	a4,3
    800048f6:	02e78663          	beq	a5,a4,80004922 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048fa:	4709                	li	a4,2
    800048fc:	0ee79163          	bne	a5,a4,800049de <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004900:	0ac05d63          	blez	a2,800049ba <filewrite+0xf4>
    int i = 0;
    80004904:	4981                	li	s3,0
    80004906:	6b05                	lui	s6,0x1
    80004908:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000490c:	6b85                	lui	s7,0x1
    8000490e:	c00b8b9b          	addiw	s7,s7,-1024
    80004912:	a861                	j	800049aa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004914:	6908                	ld	a0,16(a0)
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	22e080e7          	jalr	558(ra) # 80004b44 <pipewrite>
    8000491e:	8a2a                	mv	s4,a0
    80004920:	a045                	j	800049c0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004922:	02451783          	lh	a5,36(a0)
    80004926:	03079693          	slli	a3,a5,0x30
    8000492a:	92c1                	srli	a3,a3,0x30
    8000492c:	4725                	li	a4,9
    8000492e:	0cd76263          	bltu	a4,a3,800049f2 <filewrite+0x12c>
    80004932:	0792                	slli	a5,a5,0x4
    80004934:	0001d717          	auipc	a4,0x1d
    80004938:	be470713          	addi	a4,a4,-1052 # 80021518 <devsw>
    8000493c:	97ba                	add	a5,a5,a4
    8000493e:	679c                	ld	a5,8(a5)
    80004940:	cbdd                	beqz	a5,800049f6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004942:	4505                	li	a0,1
    80004944:	9782                	jalr	a5
    80004946:	8a2a                	mv	s4,a0
    80004948:	a8a5                	j	800049c0 <filewrite+0xfa>
    8000494a:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000494e:	00000097          	auipc	ra,0x0
    80004952:	8b0080e7          	jalr	-1872(ra) # 800041fe <begin_op>
      ilock(f->ip);
    80004956:	01893503          	ld	a0,24(s2)
    8000495a:	fffff097          	auipc	ra,0xfffff
    8000495e:	ece080e7          	jalr	-306(ra) # 80003828 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004962:	8762                	mv	a4,s8
    80004964:	02092683          	lw	a3,32(s2)
    80004968:	01598633          	add	a2,s3,s5
    8000496c:	4585                	li	a1,1
    8000496e:	01893503          	ld	a0,24(s2)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	262080e7          	jalr	610(ra) # 80003bd4 <writei>
    8000497a:	84aa                	mv	s1,a0
    8000497c:	00a05763          	blez	a0,8000498a <filewrite+0xc4>
        f->off += r;
    80004980:	02092783          	lw	a5,32(s2)
    80004984:	9fa9                	addw	a5,a5,a0
    80004986:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000498a:	01893503          	ld	a0,24(s2)
    8000498e:	fffff097          	auipc	ra,0xfffff
    80004992:	f5c080e7          	jalr	-164(ra) # 800038ea <iunlock>
      end_op();
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	8e8080e7          	jalr	-1816(ra) # 8000427e <end_op>

      if(r != n1){
    8000499e:	009c1f63          	bne	s8,s1,800049bc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049a2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049a6:	0149db63          	bge	s3,s4,800049bc <filewrite+0xf6>
      int n1 = n - i;
    800049aa:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049ae:	84be                	mv	s1,a5
    800049b0:	2781                	sext.w	a5,a5
    800049b2:	f8fb5ce3          	bge	s6,a5,8000494a <filewrite+0x84>
    800049b6:	84de                	mv	s1,s7
    800049b8:	bf49                	j	8000494a <filewrite+0x84>
    int i = 0;
    800049ba:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800049bc:	013a1f63          	bne	s4,s3,800049da <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049c0:	8552                	mv	a0,s4
    800049c2:	60a6                	ld	ra,72(sp)
    800049c4:	6406                	ld	s0,64(sp)
    800049c6:	74e2                	ld	s1,56(sp)
    800049c8:	7942                	ld	s2,48(sp)
    800049ca:	79a2                	ld	s3,40(sp)
    800049cc:	7a02                	ld	s4,32(sp)
    800049ce:	6ae2                	ld	s5,24(sp)
    800049d0:	6b42                	ld	s6,16(sp)
    800049d2:	6ba2                	ld	s7,8(sp)
    800049d4:	6c02                	ld	s8,0(sp)
    800049d6:	6161                	addi	sp,sp,80
    800049d8:	8082                	ret
    ret = (i == n ? n : -1);
    800049da:	5a7d                	li	s4,-1
    800049dc:	b7d5                	j	800049c0 <filewrite+0xfa>
    panic("filewrite");
    800049de:	00004517          	auipc	a0,0x4
    800049e2:	efa50513          	addi	a0,a0,-262 # 800088d8 <syscalls_str+0x270>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	b44080e7          	jalr	-1212(ra) # 8000052a <panic>
    return -1;
    800049ee:	5a7d                	li	s4,-1
    800049f0:	bfc1                	j	800049c0 <filewrite+0xfa>
      return -1;
    800049f2:	5a7d                	li	s4,-1
    800049f4:	b7f1                	j	800049c0 <filewrite+0xfa>
    800049f6:	5a7d                	li	s4,-1
    800049f8:	b7e1                	j	800049c0 <filewrite+0xfa>

00000000800049fa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049fa:	7179                	addi	sp,sp,-48
    800049fc:	f406                	sd	ra,40(sp)
    800049fe:	f022                	sd	s0,32(sp)
    80004a00:	ec26                	sd	s1,24(sp)
    80004a02:	e84a                	sd	s2,16(sp)
    80004a04:	e44e                	sd	s3,8(sp)
    80004a06:	e052                	sd	s4,0(sp)
    80004a08:	1800                	addi	s0,sp,48
    80004a0a:	84aa                	mv	s1,a0
    80004a0c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a0e:	0005b023          	sd	zero,0(a1)
    80004a12:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a16:	00000097          	auipc	ra,0x0
    80004a1a:	bf8080e7          	jalr	-1032(ra) # 8000460e <filealloc>
    80004a1e:	e088                	sd	a0,0(s1)
    80004a20:	c551                	beqz	a0,80004aac <pipealloc+0xb2>
    80004a22:	00000097          	auipc	ra,0x0
    80004a26:	bec080e7          	jalr	-1044(ra) # 8000460e <filealloc>
    80004a2a:	00aa3023          	sd	a0,0(s4)
    80004a2e:	c92d                	beqz	a0,80004aa0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	0a2080e7          	jalr	162(ra) # 80000ad2 <kalloc>
    80004a38:	892a                	mv	s2,a0
    80004a3a:	c125                	beqz	a0,80004a9a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a3c:	4985                	li	s3,1
    80004a3e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a42:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a46:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a4a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a4e:	00004597          	auipc	a1,0x4
    80004a52:	e9a58593          	addi	a1,a1,-358 # 800088e8 <syscalls_str+0x280>
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	0dc080e7          	jalr	220(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004a5e:	609c                	ld	a5,0(s1)
    80004a60:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a64:	609c                	ld	a5,0(s1)
    80004a66:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a6a:	609c                	ld	a5,0(s1)
    80004a6c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a70:	609c                	ld	a5,0(s1)
    80004a72:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a76:	000a3783          	ld	a5,0(s4)
    80004a7a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a7e:	000a3783          	ld	a5,0(s4)
    80004a82:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a86:	000a3783          	ld	a5,0(s4)
    80004a8a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a8e:	000a3783          	ld	a5,0(s4)
    80004a92:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a96:	4501                	li	a0,0
    80004a98:	a025                	j	80004ac0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a9a:	6088                	ld	a0,0(s1)
    80004a9c:	e501                	bnez	a0,80004aa4 <pipealloc+0xaa>
    80004a9e:	a039                	j	80004aac <pipealloc+0xb2>
    80004aa0:	6088                	ld	a0,0(s1)
    80004aa2:	c51d                	beqz	a0,80004ad0 <pipealloc+0xd6>
    fileclose(*f0);
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	c26080e7          	jalr	-986(ra) # 800046ca <fileclose>
  if(*f1)
    80004aac:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ab0:	557d                	li	a0,-1
  if(*f1)
    80004ab2:	c799                	beqz	a5,80004ac0 <pipealloc+0xc6>
    fileclose(*f1);
    80004ab4:	853e                	mv	a0,a5
    80004ab6:	00000097          	auipc	ra,0x0
    80004aba:	c14080e7          	jalr	-1004(ra) # 800046ca <fileclose>
  return -1;
    80004abe:	557d                	li	a0,-1
}
    80004ac0:	70a2                	ld	ra,40(sp)
    80004ac2:	7402                	ld	s0,32(sp)
    80004ac4:	64e2                	ld	s1,24(sp)
    80004ac6:	6942                	ld	s2,16(sp)
    80004ac8:	69a2                	ld	s3,8(sp)
    80004aca:	6a02                	ld	s4,0(sp)
    80004acc:	6145                	addi	sp,sp,48
    80004ace:	8082                	ret
  return -1;
    80004ad0:	557d                	li	a0,-1
    80004ad2:	b7fd                	j	80004ac0 <pipealloc+0xc6>

0000000080004ad4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ad4:	1101                	addi	sp,sp,-32
    80004ad6:	ec06                	sd	ra,24(sp)
    80004ad8:	e822                	sd	s0,16(sp)
    80004ada:	e426                	sd	s1,8(sp)
    80004adc:	e04a                	sd	s2,0(sp)
    80004ade:	1000                	addi	s0,sp,32
    80004ae0:	84aa                	mv	s1,a0
    80004ae2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	0de080e7          	jalr	222(ra) # 80000bc2 <acquire>
  if(writable){
    80004aec:	02090d63          	beqz	s2,80004b26 <pipeclose+0x52>
    pi->writeopen = 0;
    80004af0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004af4:	21848513          	addi	a0,s1,536
    80004af8:	ffffd097          	auipc	ra,0xffffd
    80004afc:	740080e7          	jalr	1856(ra) # 80002238 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b00:	2204b783          	ld	a5,544(s1)
    80004b04:	eb95                	bnez	a5,80004b38 <pipeclose+0x64>
    release(&pi->lock);
    80004b06:	8526                	mv	a0,s1
    80004b08:	ffffc097          	auipc	ra,0xffffc
    80004b0c:	16e080e7          	jalr	366(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004b10:	8526                	mv	a0,s1
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	ec4080e7          	jalr	-316(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004b1a:	60e2                	ld	ra,24(sp)
    80004b1c:	6442                	ld	s0,16(sp)
    80004b1e:	64a2                	ld	s1,8(sp)
    80004b20:	6902                	ld	s2,0(sp)
    80004b22:	6105                	addi	sp,sp,32
    80004b24:	8082                	ret
    pi->readopen = 0;
    80004b26:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b2a:	21c48513          	addi	a0,s1,540
    80004b2e:	ffffd097          	auipc	ra,0xffffd
    80004b32:	70a080e7          	jalr	1802(ra) # 80002238 <wakeup>
    80004b36:	b7e9                	j	80004b00 <pipeclose+0x2c>
    release(&pi->lock);
    80004b38:	8526                	mv	a0,s1
    80004b3a:	ffffc097          	auipc	ra,0xffffc
    80004b3e:	13c080e7          	jalr	316(ra) # 80000c76 <release>
}
    80004b42:	bfe1                	j	80004b1a <pipeclose+0x46>

0000000080004b44 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b44:	711d                	addi	sp,sp,-96
    80004b46:	ec86                	sd	ra,88(sp)
    80004b48:	e8a2                	sd	s0,80(sp)
    80004b4a:	e4a6                	sd	s1,72(sp)
    80004b4c:	e0ca                	sd	s2,64(sp)
    80004b4e:	fc4e                	sd	s3,56(sp)
    80004b50:	f852                	sd	s4,48(sp)
    80004b52:	f456                	sd	s5,40(sp)
    80004b54:	f05a                	sd	s6,32(sp)
    80004b56:	ec5e                	sd	s7,24(sp)
    80004b58:	e862                	sd	s8,16(sp)
    80004b5a:	1080                	addi	s0,sp,96
    80004b5c:	84aa                	mv	s1,a0
    80004b5e:	8aae                	mv	s5,a1
    80004b60:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004b62:	ffffd097          	auipc	ra,0xffffd
    80004b66:	e30080e7          	jalr	-464(ra) # 80001992 <myproc>
    80004b6a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004b6c:	8526                	mv	a0,s1
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	054080e7          	jalr	84(ra) # 80000bc2 <acquire>
  while(i < n){
    80004b76:	0b405363          	blez	s4,80004c1c <pipewrite+0xd8>
  int i = 0;
    80004b7a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b7c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b7e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b82:	21c48b93          	addi	s7,s1,540
    80004b86:	a089                	j	80004bc8 <pipewrite+0x84>
      release(&pi->lock);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	0ec080e7          	jalr	236(ra) # 80000c76 <release>
      return -1;
    80004b92:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b94:	854a                	mv	a0,s2
    80004b96:	60e6                	ld	ra,88(sp)
    80004b98:	6446                	ld	s0,80(sp)
    80004b9a:	64a6                	ld	s1,72(sp)
    80004b9c:	6906                	ld	s2,64(sp)
    80004b9e:	79e2                	ld	s3,56(sp)
    80004ba0:	7a42                	ld	s4,48(sp)
    80004ba2:	7aa2                	ld	s5,40(sp)
    80004ba4:	7b02                	ld	s6,32(sp)
    80004ba6:	6be2                	ld	s7,24(sp)
    80004ba8:	6c42                	ld	s8,16(sp)
    80004baa:	6125                	addi	sp,sp,96
    80004bac:	8082                	ret
      wakeup(&pi->nread);
    80004bae:	8562                	mv	a0,s8
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	688080e7          	jalr	1672(ra) # 80002238 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bb8:	85a6                	mv	a1,s1
    80004bba:	855e                	mv	a0,s7
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	4f0080e7          	jalr	1264(ra) # 800020ac <sleep>
  while(i < n){
    80004bc4:	05495d63          	bge	s2,s4,80004c1e <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004bc8:	2204a783          	lw	a5,544(s1)
    80004bcc:	dfd5                	beqz	a5,80004b88 <pipewrite+0x44>
    80004bce:	0289a783          	lw	a5,40(s3)
    80004bd2:	fbdd                	bnez	a5,80004b88 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004bd4:	2184a783          	lw	a5,536(s1)
    80004bd8:	21c4a703          	lw	a4,540(s1)
    80004bdc:	2007879b          	addiw	a5,a5,512
    80004be0:	fcf707e3          	beq	a4,a5,80004bae <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004be4:	4685                	li	a3,1
    80004be6:	01590633          	add	a2,s2,s5
    80004bea:	faf40593          	addi	a1,s0,-81
    80004bee:	0509b503          	ld	a0,80(s3)
    80004bf2:	ffffd097          	auipc	ra,0xffffd
    80004bf6:	ad8080e7          	jalr	-1320(ra) # 800016ca <copyin>
    80004bfa:	03650263          	beq	a0,s6,80004c1e <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bfe:	21c4a783          	lw	a5,540(s1)
    80004c02:	0017871b          	addiw	a4,a5,1
    80004c06:	20e4ae23          	sw	a4,540(s1)
    80004c0a:	1ff7f793          	andi	a5,a5,511
    80004c0e:	97a6                	add	a5,a5,s1
    80004c10:	faf44703          	lbu	a4,-81(s0)
    80004c14:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c18:	2905                	addiw	s2,s2,1
    80004c1a:	b76d                	j	80004bc4 <pipewrite+0x80>
  int i = 0;
    80004c1c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c1e:	21848513          	addi	a0,s1,536
    80004c22:	ffffd097          	auipc	ra,0xffffd
    80004c26:	616080e7          	jalr	1558(ra) # 80002238 <wakeup>
  release(&pi->lock);
    80004c2a:	8526                	mv	a0,s1
    80004c2c:	ffffc097          	auipc	ra,0xffffc
    80004c30:	04a080e7          	jalr	74(ra) # 80000c76 <release>
  return i;
    80004c34:	b785                	j	80004b94 <pipewrite+0x50>

0000000080004c36 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c36:	715d                	addi	sp,sp,-80
    80004c38:	e486                	sd	ra,72(sp)
    80004c3a:	e0a2                	sd	s0,64(sp)
    80004c3c:	fc26                	sd	s1,56(sp)
    80004c3e:	f84a                	sd	s2,48(sp)
    80004c40:	f44e                	sd	s3,40(sp)
    80004c42:	f052                	sd	s4,32(sp)
    80004c44:	ec56                	sd	s5,24(sp)
    80004c46:	e85a                	sd	s6,16(sp)
    80004c48:	0880                	addi	s0,sp,80
    80004c4a:	84aa                	mv	s1,a0
    80004c4c:	892e                	mv	s2,a1
    80004c4e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c50:	ffffd097          	auipc	ra,0xffffd
    80004c54:	d42080e7          	jalr	-702(ra) # 80001992 <myproc>
    80004c58:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c5a:	8526                	mv	a0,s1
    80004c5c:	ffffc097          	auipc	ra,0xffffc
    80004c60:	f66080e7          	jalr	-154(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c64:	2184a703          	lw	a4,536(s1)
    80004c68:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c6c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c70:	02f71463          	bne	a4,a5,80004c98 <piperead+0x62>
    80004c74:	2244a783          	lw	a5,548(s1)
    80004c78:	c385                	beqz	a5,80004c98 <piperead+0x62>
    if(pr->killed){
    80004c7a:	028a2783          	lw	a5,40(s4)
    80004c7e:	ebc1                	bnez	a5,80004d0e <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c80:	85a6                	mv	a1,s1
    80004c82:	854e                	mv	a0,s3
    80004c84:	ffffd097          	auipc	ra,0xffffd
    80004c88:	428080e7          	jalr	1064(ra) # 800020ac <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c8c:	2184a703          	lw	a4,536(s1)
    80004c90:	21c4a783          	lw	a5,540(s1)
    80004c94:	fef700e3          	beq	a4,a5,80004c74 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c98:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c9a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c9c:	05505363          	blez	s5,80004ce2 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004ca0:	2184a783          	lw	a5,536(s1)
    80004ca4:	21c4a703          	lw	a4,540(s1)
    80004ca8:	02f70d63          	beq	a4,a5,80004ce2 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cac:	0017871b          	addiw	a4,a5,1
    80004cb0:	20e4ac23          	sw	a4,536(s1)
    80004cb4:	1ff7f793          	andi	a5,a5,511
    80004cb8:	97a6                	add	a5,a5,s1
    80004cba:	0187c783          	lbu	a5,24(a5)
    80004cbe:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cc2:	4685                	li	a3,1
    80004cc4:	fbf40613          	addi	a2,s0,-65
    80004cc8:	85ca                	mv	a1,s2
    80004cca:	050a3503          	ld	a0,80(s4)
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	970080e7          	jalr	-1680(ra) # 8000163e <copyout>
    80004cd6:	01650663          	beq	a0,s6,80004ce2 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cda:	2985                	addiw	s3,s3,1
    80004cdc:	0905                	addi	s2,s2,1
    80004cde:	fd3a91e3          	bne	s5,s3,80004ca0 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ce2:	21c48513          	addi	a0,s1,540
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	552080e7          	jalr	1362(ra) # 80002238 <wakeup>
  release(&pi->lock);
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	f86080e7          	jalr	-122(ra) # 80000c76 <release>
  return i;
}
    80004cf8:	854e                	mv	a0,s3
    80004cfa:	60a6                	ld	ra,72(sp)
    80004cfc:	6406                	ld	s0,64(sp)
    80004cfe:	74e2                	ld	s1,56(sp)
    80004d00:	7942                	ld	s2,48(sp)
    80004d02:	79a2                	ld	s3,40(sp)
    80004d04:	7a02                	ld	s4,32(sp)
    80004d06:	6ae2                	ld	s5,24(sp)
    80004d08:	6b42                	ld	s6,16(sp)
    80004d0a:	6161                	addi	sp,sp,80
    80004d0c:	8082                	ret
      release(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	f66080e7          	jalr	-154(ra) # 80000c76 <release>
      return -1;
    80004d18:	59fd                	li	s3,-1
    80004d1a:	bff9                	j	80004cf8 <piperead+0xc2>

0000000080004d1c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d1c:	de010113          	addi	sp,sp,-544
    80004d20:	20113c23          	sd	ra,536(sp)
    80004d24:	20813823          	sd	s0,528(sp)
    80004d28:	20913423          	sd	s1,520(sp)
    80004d2c:	21213023          	sd	s2,512(sp)
    80004d30:	ffce                	sd	s3,504(sp)
    80004d32:	fbd2                	sd	s4,496(sp)
    80004d34:	f7d6                	sd	s5,488(sp)
    80004d36:	f3da                	sd	s6,480(sp)
    80004d38:	efde                	sd	s7,472(sp)
    80004d3a:	ebe2                	sd	s8,464(sp)
    80004d3c:	e7e6                	sd	s9,456(sp)
    80004d3e:	e3ea                	sd	s10,448(sp)
    80004d40:	ff6e                	sd	s11,440(sp)
    80004d42:	1400                	addi	s0,sp,544
    80004d44:	892a                	mv	s2,a0
    80004d46:	dea43423          	sd	a0,-536(s0)
    80004d4a:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d4e:	ffffd097          	auipc	ra,0xffffd
    80004d52:	c44080e7          	jalr	-956(ra) # 80001992 <myproc>
    80004d56:	84aa                	mv	s1,a0

  begin_op();
    80004d58:	fffff097          	auipc	ra,0xfffff
    80004d5c:	4a6080e7          	jalr	1190(ra) # 800041fe <begin_op>

  if((ip = namei(path)) == 0){
    80004d60:	854a                	mv	a0,s2
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	27c080e7          	jalr	636(ra) # 80003fde <namei>
    80004d6a:	c93d                	beqz	a0,80004de0 <exec+0xc4>
    80004d6c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	aba080e7          	jalr	-1350(ra) # 80003828 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d76:	04000713          	li	a4,64
    80004d7a:	4681                	li	a3,0
    80004d7c:	e4840613          	addi	a2,s0,-440
    80004d80:	4581                	li	a1,0
    80004d82:	8556                	mv	a0,s5
    80004d84:	fffff097          	auipc	ra,0xfffff
    80004d88:	d58080e7          	jalr	-680(ra) # 80003adc <readi>
    80004d8c:	04000793          	li	a5,64
    80004d90:	00f51a63          	bne	a0,a5,80004da4 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d94:	e4842703          	lw	a4,-440(s0)
    80004d98:	464c47b7          	lui	a5,0x464c4
    80004d9c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004da0:	04f70663          	beq	a4,a5,80004dec <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004da4:	8556                	mv	a0,s5
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	ce4080e7          	jalr	-796(ra) # 80003a8a <iunlockput>
    end_op();
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	4d0080e7          	jalr	1232(ra) # 8000427e <end_op>
  }
  return -1;
    80004db6:	557d                	li	a0,-1
}
    80004db8:	21813083          	ld	ra,536(sp)
    80004dbc:	21013403          	ld	s0,528(sp)
    80004dc0:	20813483          	ld	s1,520(sp)
    80004dc4:	20013903          	ld	s2,512(sp)
    80004dc8:	79fe                	ld	s3,504(sp)
    80004dca:	7a5e                	ld	s4,496(sp)
    80004dcc:	7abe                	ld	s5,488(sp)
    80004dce:	7b1e                	ld	s6,480(sp)
    80004dd0:	6bfe                	ld	s7,472(sp)
    80004dd2:	6c5e                	ld	s8,464(sp)
    80004dd4:	6cbe                	ld	s9,456(sp)
    80004dd6:	6d1e                	ld	s10,448(sp)
    80004dd8:	7dfa                	ld	s11,440(sp)
    80004dda:	22010113          	addi	sp,sp,544
    80004dde:	8082                	ret
    end_op();
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	49e080e7          	jalr	1182(ra) # 8000427e <end_op>
    return -1;
    80004de8:	557d                	li	a0,-1
    80004dea:	b7f9                	j	80004db8 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	c68080e7          	jalr	-920(ra) # 80001a56 <proc_pagetable>
    80004df6:	8b2a                	mv	s6,a0
    80004df8:	d555                	beqz	a0,80004da4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dfa:	e6842783          	lw	a5,-408(s0)
    80004dfe:	e8045703          	lhu	a4,-384(s0)
    80004e02:	c735                	beqz	a4,80004e6e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e04:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e06:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e0a:	6a05                	lui	s4,0x1
    80004e0c:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e10:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004e14:	6d85                	lui	s11,0x1
    80004e16:	7d7d                	lui	s10,0xfffff
    80004e18:	ac1d                	j	8000504e <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e1a:	00004517          	auipc	a0,0x4
    80004e1e:	ad650513          	addi	a0,a0,-1322 # 800088f0 <syscalls_str+0x288>
    80004e22:	ffffb097          	auipc	ra,0xffffb
    80004e26:	708080e7          	jalr	1800(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e2a:	874a                	mv	a4,s2
    80004e2c:	009c86bb          	addw	a3,s9,s1
    80004e30:	4581                	li	a1,0
    80004e32:	8556                	mv	a0,s5
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	ca8080e7          	jalr	-856(ra) # 80003adc <readi>
    80004e3c:	2501                	sext.w	a0,a0
    80004e3e:	1aa91863          	bne	s2,a0,80004fee <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004e42:	009d84bb          	addw	s1,s11,s1
    80004e46:	013d09bb          	addw	s3,s10,s3
    80004e4a:	1f74f263          	bgeu	s1,s7,8000502e <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004e4e:	02049593          	slli	a1,s1,0x20
    80004e52:	9181                	srli	a1,a1,0x20
    80004e54:	95e2                	add	a1,a1,s8
    80004e56:	855a                	mv	a0,s6
    80004e58:	ffffc097          	auipc	ra,0xffffc
    80004e5c:	1f4080e7          	jalr	500(ra) # 8000104c <walkaddr>
    80004e60:	862a                	mv	a2,a0
    if(pa == 0)
    80004e62:	dd45                	beqz	a0,80004e1a <exec+0xfe>
      n = PGSIZE;
    80004e64:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e66:	fd49f2e3          	bgeu	s3,s4,80004e2a <exec+0x10e>
      n = sz - i;
    80004e6a:	894e                	mv	s2,s3
    80004e6c:	bf7d                	j	80004e2a <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e6e:	4481                	li	s1,0
  iunlockput(ip);
    80004e70:	8556                	mv	a0,s5
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	c18080e7          	jalr	-1000(ra) # 80003a8a <iunlockput>
  end_op();
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	404080e7          	jalr	1028(ra) # 8000427e <end_op>
  p = myproc();
    80004e82:	ffffd097          	auipc	ra,0xffffd
    80004e86:	b10080e7          	jalr	-1264(ra) # 80001992 <myproc>
    80004e8a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e8c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e90:	6785                	lui	a5,0x1
    80004e92:	17fd                	addi	a5,a5,-1
    80004e94:	94be                	add	s1,s1,a5
    80004e96:	77fd                	lui	a5,0xfffff
    80004e98:	8fe5                	and	a5,a5,s1
    80004e9a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e9e:	6609                	lui	a2,0x2
    80004ea0:	963e                	add	a2,a2,a5
    80004ea2:	85be                	mv	a1,a5
    80004ea4:	855a                	mv	a0,s6
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	548080e7          	jalr	1352(ra) # 800013ee <uvmalloc>
    80004eae:	8c2a                	mv	s8,a0
  ip = 0;
    80004eb0:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eb2:	12050e63          	beqz	a0,80004fee <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004eb6:	75f9                	lui	a1,0xffffe
    80004eb8:	95aa                	add	a1,a1,a0
    80004eba:	855a                	mv	a0,s6
    80004ebc:	ffffc097          	auipc	ra,0xffffc
    80004ec0:	750080e7          	jalr	1872(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    80004ec4:	7afd                	lui	s5,0xfffff
    80004ec6:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ec8:	df043783          	ld	a5,-528(s0)
    80004ecc:	6388                	ld	a0,0(a5)
    80004ece:	c925                	beqz	a0,80004f3e <exec+0x222>
    80004ed0:	e8840993          	addi	s3,s0,-376
    80004ed4:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004ed8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eda:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	f66080e7          	jalr	-154(ra) # 80000e42 <strlen>
    80004ee4:	0015079b          	addiw	a5,a0,1
    80004ee8:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004eec:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ef0:	13596363          	bltu	s2,s5,80005016 <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ef4:	df043d83          	ld	s11,-528(s0)
    80004ef8:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004efc:	8552                	mv	a0,s4
    80004efe:	ffffc097          	auipc	ra,0xffffc
    80004f02:	f44080e7          	jalr	-188(ra) # 80000e42 <strlen>
    80004f06:	0015069b          	addiw	a3,a0,1
    80004f0a:	8652                	mv	a2,s4
    80004f0c:	85ca                	mv	a1,s2
    80004f0e:	855a                	mv	a0,s6
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	72e080e7          	jalr	1838(ra) # 8000163e <copyout>
    80004f18:	10054363          	bltz	a0,8000501e <exec+0x302>
    ustack[argc] = sp;
    80004f1c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f20:	0485                	addi	s1,s1,1
    80004f22:	008d8793          	addi	a5,s11,8
    80004f26:	def43823          	sd	a5,-528(s0)
    80004f2a:	008db503          	ld	a0,8(s11)
    80004f2e:	c911                	beqz	a0,80004f42 <exec+0x226>
    if(argc >= MAXARG)
    80004f30:	09a1                	addi	s3,s3,8
    80004f32:	fb3c95e3          	bne	s9,s3,80004edc <exec+0x1c0>
  sz = sz1;
    80004f36:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f3a:	4a81                	li	s5,0
    80004f3c:	a84d                	j	80004fee <exec+0x2d2>
  sp = sz;
    80004f3e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f40:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f42:	00349793          	slli	a5,s1,0x3
    80004f46:	f9040713          	addi	a4,s0,-112
    80004f4a:	97ba                	add	a5,a5,a4
    80004f4c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f50:	00148693          	addi	a3,s1,1
    80004f54:	068e                	slli	a3,a3,0x3
    80004f56:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f5a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f5e:	01597663          	bgeu	s2,s5,80004f6a <exec+0x24e>
  sz = sz1;
    80004f62:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f66:	4a81                	li	s5,0
    80004f68:	a059                	j	80004fee <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f6a:	e8840613          	addi	a2,s0,-376
    80004f6e:	85ca                	mv	a1,s2
    80004f70:	855a                	mv	a0,s6
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	6cc080e7          	jalr	1740(ra) # 8000163e <copyout>
    80004f7a:	0a054663          	bltz	a0,80005026 <exec+0x30a>
  p->trapframe->a1 = sp;
    80004f7e:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80004f82:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f86:	de843783          	ld	a5,-536(s0)
    80004f8a:	0007c703          	lbu	a4,0(a5)
    80004f8e:	cf11                	beqz	a4,80004faa <exec+0x28e>
    80004f90:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f92:	02f00693          	li	a3,47
    80004f96:	a039                	j	80004fa4 <exec+0x288>
      last = s+1;
    80004f98:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f9c:	0785                	addi	a5,a5,1
    80004f9e:	fff7c703          	lbu	a4,-1(a5)
    80004fa2:	c701                	beqz	a4,80004faa <exec+0x28e>
    if(*s == '/')
    80004fa4:	fed71ce3          	bne	a4,a3,80004f9c <exec+0x280>
    80004fa8:	bfc5                	j	80004f98 <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    80004faa:	4641                	li	a2,16
    80004fac:	de843583          	ld	a1,-536(s0)
    80004fb0:	158b8513          	addi	a0,s7,344
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	e5c080e7          	jalr	-420(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fbc:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004fc0:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004fc4:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fc8:	058bb783          	ld	a5,88(s7)
    80004fcc:	e6043703          	ld	a4,-416(s0)
    80004fd0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fd2:	058bb783          	ld	a5,88(s7)
    80004fd6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fda:	85ea                	mv	a1,s10
    80004fdc:	ffffd097          	auipc	ra,0xffffd
    80004fe0:	b16080e7          	jalr	-1258(ra) # 80001af2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fe4:	0004851b          	sext.w	a0,s1
    80004fe8:	bbc1                	j	80004db8 <exec+0x9c>
    80004fea:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fee:	df843583          	ld	a1,-520(s0)
    80004ff2:	855a                	mv	a0,s6
    80004ff4:	ffffd097          	auipc	ra,0xffffd
    80004ff8:	afe080e7          	jalr	-1282(ra) # 80001af2 <proc_freepagetable>
  if(ip){
    80004ffc:	da0a94e3          	bnez	s5,80004da4 <exec+0x88>
  return -1;
    80005000:	557d                	li	a0,-1
    80005002:	bb5d                	j	80004db8 <exec+0x9c>
    80005004:	de943c23          	sd	s1,-520(s0)
    80005008:	b7dd                	j	80004fee <exec+0x2d2>
    8000500a:	de943c23          	sd	s1,-520(s0)
    8000500e:	b7c5                	j	80004fee <exec+0x2d2>
    80005010:	de943c23          	sd	s1,-520(s0)
    80005014:	bfe9                	j	80004fee <exec+0x2d2>
  sz = sz1;
    80005016:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000501a:	4a81                	li	s5,0
    8000501c:	bfc9                	j	80004fee <exec+0x2d2>
  sz = sz1;
    8000501e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005022:	4a81                	li	s5,0
    80005024:	b7e9                	j	80004fee <exec+0x2d2>
  sz = sz1;
    80005026:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000502a:	4a81                	li	s5,0
    8000502c:	b7c9                	j	80004fee <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000502e:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005032:	e0843783          	ld	a5,-504(s0)
    80005036:	0017869b          	addiw	a3,a5,1
    8000503a:	e0d43423          	sd	a3,-504(s0)
    8000503e:	e0043783          	ld	a5,-512(s0)
    80005042:	0387879b          	addiw	a5,a5,56
    80005046:	e8045703          	lhu	a4,-384(s0)
    8000504a:	e2e6d3e3          	bge	a3,a4,80004e70 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000504e:	2781                	sext.w	a5,a5
    80005050:	e0f43023          	sd	a5,-512(s0)
    80005054:	03800713          	li	a4,56
    80005058:	86be                	mv	a3,a5
    8000505a:	e1040613          	addi	a2,s0,-496
    8000505e:	4581                	li	a1,0
    80005060:	8556                	mv	a0,s5
    80005062:	fffff097          	auipc	ra,0xfffff
    80005066:	a7a080e7          	jalr	-1414(ra) # 80003adc <readi>
    8000506a:	03800793          	li	a5,56
    8000506e:	f6f51ee3          	bne	a0,a5,80004fea <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005072:	e1042783          	lw	a5,-496(s0)
    80005076:	4705                	li	a4,1
    80005078:	fae79de3          	bne	a5,a4,80005032 <exec+0x316>
    if(ph.memsz < ph.filesz)
    8000507c:	e3843603          	ld	a2,-456(s0)
    80005080:	e3043783          	ld	a5,-464(s0)
    80005084:	f8f660e3          	bltu	a2,a5,80005004 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005088:	e2043783          	ld	a5,-480(s0)
    8000508c:	963e                	add	a2,a2,a5
    8000508e:	f6f66ee3          	bltu	a2,a5,8000500a <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005092:	85a6                	mv	a1,s1
    80005094:	855a                	mv	a0,s6
    80005096:	ffffc097          	auipc	ra,0xffffc
    8000509a:	358080e7          	jalr	856(ra) # 800013ee <uvmalloc>
    8000509e:	dea43c23          	sd	a0,-520(s0)
    800050a2:	d53d                	beqz	a0,80005010 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    800050a4:	e2043c03          	ld	s8,-480(s0)
    800050a8:	de043783          	ld	a5,-544(s0)
    800050ac:	00fc77b3          	and	a5,s8,a5
    800050b0:	ff9d                	bnez	a5,80004fee <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050b2:	e1842c83          	lw	s9,-488(s0)
    800050b6:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050ba:	f60b8ae3          	beqz	s7,8000502e <exec+0x312>
    800050be:	89de                	mv	s3,s7
    800050c0:	4481                	li	s1,0
    800050c2:	b371                	j	80004e4e <exec+0x132>

00000000800050c4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050c4:	7179                	addi	sp,sp,-48
    800050c6:	f406                	sd	ra,40(sp)
    800050c8:	f022                	sd	s0,32(sp)
    800050ca:	ec26                	sd	s1,24(sp)
    800050cc:	e84a                	sd	s2,16(sp)
    800050ce:	1800                	addi	s0,sp,48
    800050d0:	892e                	mv	s2,a1
    800050d2:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050d4:	fdc40593          	addi	a1,s0,-36
    800050d8:	ffffe097          	auipc	ra,0xffffe
    800050dc:	ae8080e7          	jalr	-1304(ra) # 80002bc0 <argint>
    800050e0:	04054063          	bltz	a0,80005120 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050e4:	fdc42703          	lw	a4,-36(s0)
    800050e8:	47bd                	li	a5,15
    800050ea:	02e7ed63          	bltu	a5,a4,80005124 <argfd+0x60>
    800050ee:	ffffd097          	auipc	ra,0xffffd
    800050f2:	8a4080e7          	jalr	-1884(ra) # 80001992 <myproc>
    800050f6:	fdc42703          	lw	a4,-36(s0)
    800050fa:	01a70793          	addi	a5,a4,26
    800050fe:	078e                	slli	a5,a5,0x3
    80005100:	953e                	add	a0,a0,a5
    80005102:	611c                	ld	a5,0(a0)
    80005104:	c395                	beqz	a5,80005128 <argfd+0x64>
    return -1;
  if(pfd)
    80005106:	00090463          	beqz	s2,8000510e <argfd+0x4a>
    *pfd = fd;
    8000510a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000510e:	4501                	li	a0,0
  if(pf)
    80005110:	c091                	beqz	s1,80005114 <argfd+0x50>
    *pf = f;
    80005112:	e09c                	sd	a5,0(s1)
}
    80005114:	70a2                	ld	ra,40(sp)
    80005116:	7402                	ld	s0,32(sp)
    80005118:	64e2                	ld	s1,24(sp)
    8000511a:	6942                	ld	s2,16(sp)
    8000511c:	6145                	addi	sp,sp,48
    8000511e:	8082                	ret
    return -1;
    80005120:	557d                	li	a0,-1
    80005122:	bfcd                	j	80005114 <argfd+0x50>
    return -1;
    80005124:	557d                	li	a0,-1
    80005126:	b7fd                	j	80005114 <argfd+0x50>
    80005128:	557d                	li	a0,-1
    8000512a:	b7ed                	j	80005114 <argfd+0x50>

000000008000512c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000512c:	1101                	addi	sp,sp,-32
    8000512e:	ec06                	sd	ra,24(sp)
    80005130:	e822                	sd	s0,16(sp)
    80005132:	e426                	sd	s1,8(sp)
    80005134:	1000                	addi	s0,sp,32
    80005136:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005138:	ffffd097          	auipc	ra,0xffffd
    8000513c:	85a080e7          	jalr	-1958(ra) # 80001992 <myproc>
    80005140:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005142:	0d050793          	addi	a5,a0,208
    80005146:	4501                	li	a0,0
    80005148:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000514a:	6398                	ld	a4,0(a5)
    8000514c:	cb19                	beqz	a4,80005162 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000514e:	2505                	addiw	a0,a0,1
    80005150:	07a1                	addi	a5,a5,8
    80005152:	fed51ce3          	bne	a0,a3,8000514a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005156:	557d                	li	a0,-1
}
    80005158:	60e2                	ld	ra,24(sp)
    8000515a:	6442                	ld	s0,16(sp)
    8000515c:	64a2                	ld	s1,8(sp)
    8000515e:	6105                	addi	sp,sp,32
    80005160:	8082                	ret
      p->ofile[fd] = f;
    80005162:	01a50793          	addi	a5,a0,26
    80005166:	078e                	slli	a5,a5,0x3
    80005168:	963e                	add	a2,a2,a5
    8000516a:	e204                	sd	s1,0(a2)
      return fd;
    8000516c:	b7f5                	j	80005158 <fdalloc+0x2c>

000000008000516e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000516e:	715d                	addi	sp,sp,-80
    80005170:	e486                	sd	ra,72(sp)
    80005172:	e0a2                	sd	s0,64(sp)
    80005174:	fc26                	sd	s1,56(sp)
    80005176:	f84a                	sd	s2,48(sp)
    80005178:	f44e                	sd	s3,40(sp)
    8000517a:	f052                	sd	s4,32(sp)
    8000517c:	ec56                	sd	s5,24(sp)
    8000517e:	0880                	addi	s0,sp,80
    80005180:	89ae                	mv	s3,a1
    80005182:	8ab2                	mv	s5,a2
    80005184:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005186:	fb040593          	addi	a1,s0,-80
    8000518a:	fffff097          	auipc	ra,0xfffff
    8000518e:	e72080e7          	jalr	-398(ra) # 80003ffc <nameiparent>
    80005192:	892a                	mv	s2,a0
    80005194:	12050e63          	beqz	a0,800052d0 <create+0x162>
    return 0;

  ilock(dp);
    80005198:	ffffe097          	auipc	ra,0xffffe
    8000519c:	690080e7          	jalr	1680(ra) # 80003828 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051a0:	4601                	li	a2,0
    800051a2:	fb040593          	addi	a1,s0,-80
    800051a6:	854a                	mv	a0,s2
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	b64080e7          	jalr	-1180(ra) # 80003d0c <dirlookup>
    800051b0:	84aa                	mv	s1,a0
    800051b2:	c921                	beqz	a0,80005202 <create+0x94>
    iunlockput(dp);
    800051b4:	854a                	mv	a0,s2
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	8d4080e7          	jalr	-1836(ra) # 80003a8a <iunlockput>
    ilock(ip);
    800051be:	8526                	mv	a0,s1
    800051c0:	ffffe097          	auipc	ra,0xffffe
    800051c4:	668080e7          	jalr	1640(ra) # 80003828 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051c8:	2981                	sext.w	s3,s3
    800051ca:	4789                	li	a5,2
    800051cc:	02f99463          	bne	s3,a5,800051f4 <create+0x86>
    800051d0:	0444d783          	lhu	a5,68(s1)
    800051d4:	37f9                	addiw	a5,a5,-2
    800051d6:	17c2                	slli	a5,a5,0x30
    800051d8:	93c1                	srli	a5,a5,0x30
    800051da:	4705                	li	a4,1
    800051dc:	00f76c63          	bltu	a4,a5,800051f4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051e0:	8526                	mv	a0,s1
    800051e2:	60a6                	ld	ra,72(sp)
    800051e4:	6406                	ld	s0,64(sp)
    800051e6:	74e2                	ld	s1,56(sp)
    800051e8:	7942                	ld	s2,48(sp)
    800051ea:	79a2                	ld	s3,40(sp)
    800051ec:	7a02                	ld	s4,32(sp)
    800051ee:	6ae2                	ld	s5,24(sp)
    800051f0:	6161                	addi	sp,sp,80
    800051f2:	8082                	ret
    iunlockput(ip);
    800051f4:	8526                	mv	a0,s1
    800051f6:	fffff097          	auipc	ra,0xfffff
    800051fa:	894080e7          	jalr	-1900(ra) # 80003a8a <iunlockput>
    return 0;
    800051fe:	4481                	li	s1,0
    80005200:	b7c5                	j	800051e0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005202:	85ce                	mv	a1,s3
    80005204:	00092503          	lw	a0,0(s2)
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	488080e7          	jalr	1160(ra) # 80003690 <ialloc>
    80005210:	84aa                	mv	s1,a0
    80005212:	c521                	beqz	a0,8000525a <create+0xec>
  ilock(ip);
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	614080e7          	jalr	1556(ra) # 80003828 <ilock>
  ip->major = major;
    8000521c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005220:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005224:	4a05                	li	s4,1
    80005226:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000522a:	8526                	mv	a0,s1
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	532080e7          	jalr	1330(ra) # 8000375e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005234:	2981                	sext.w	s3,s3
    80005236:	03498a63          	beq	s3,s4,8000526a <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000523a:	40d0                	lw	a2,4(s1)
    8000523c:	fb040593          	addi	a1,s0,-80
    80005240:	854a                	mv	a0,s2
    80005242:	fffff097          	auipc	ra,0xfffff
    80005246:	cda080e7          	jalr	-806(ra) # 80003f1c <dirlink>
    8000524a:	06054b63          	bltz	a0,800052c0 <create+0x152>
  iunlockput(dp);
    8000524e:	854a                	mv	a0,s2
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	83a080e7          	jalr	-1990(ra) # 80003a8a <iunlockput>
  return ip;
    80005258:	b761                	j	800051e0 <create+0x72>
    panic("create: ialloc");
    8000525a:	00003517          	auipc	a0,0x3
    8000525e:	6b650513          	addi	a0,a0,1718 # 80008910 <syscalls_str+0x2a8>
    80005262:	ffffb097          	auipc	ra,0xffffb
    80005266:	2c8080e7          	jalr	712(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000526a:	04a95783          	lhu	a5,74(s2)
    8000526e:	2785                	addiw	a5,a5,1
    80005270:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005274:	854a                	mv	a0,s2
    80005276:	ffffe097          	auipc	ra,0xffffe
    8000527a:	4e8080e7          	jalr	1256(ra) # 8000375e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000527e:	40d0                	lw	a2,4(s1)
    80005280:	00003597          	auipc	a1,0x3
    80005284:	6a058593          	addi	a1,a1,1696 # 80008920 <syscalls_str+0x2b8>
    80005288:	8526                	mv	a0,s1
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	c92080e7          	jalr	-878(ra) # 80003f1c <dirlink>
    80005292:	00054f63          	bltz	a0,800052b0 <create+0x142>
    80005296:	00492603          	lw	a2,4(s2)
    8000529a:	00003597          	auipc	a1,0x3
    8000529e:	68e58593          	addi	a1,a1,1678 # 80008928 <syscalls_str+0x2c0>
    800052a2:	8526                	mv	a0,s1
    800052a4:	fffff097          	auipc	ra,0xfffff
    800052a8:	c78080e7          	jalr	-904(ra) # 80003f1c <dirlink>
    800052ac:	f80557e3          	bgez	a0,8000523a <create+0xcc>
      panic("create dots");
    800052b0:	00003517          	auipc	a0,0x3
    800052b4:	68050513          	addi	a0,a0,1664 # 80008930 <syscalls_str+0x2c8>
    800052b8:	ffffb097          	auipc	ra,0xffffb
    800052bc:	272080e7          	jalr	626(ra) # 8000052a <panic>
    panic("create: dirlink");
    800052c0:	00003517          	auipc	a0,0x3
    800052c4:	68050513          	addi	a0,a0,1664 # 80008940 <syscalls_str+0x2d8>
    800052c8:	ffffb097          	auipc	ra,0xffffb
    800052cc:	262080e7          	jalr	610(ra) # 8000052a <panic>
    return 0;
    800052d0:	84aa                	mv	s1,a0
    800052d2:	b739                	j	800051e0 <create+0x72>

00000000800052d4 <sys_dup>:
{
    800052d4:	7179                	addi	sp,sp,-48
    800052d6:	f406                	sd	ra,40(sp)
    800052d8:	f022                	sd	s0,32(sp)
    800052da:	ec26                	sd	s1,24(sp)
    800052dc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052de:	fd840613          	addi	a2,s0,-40
    800052e2:	4581                	li	a1,0
    800052e4:	4501                	li	a0,0
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	dde080e7          	jalr	-546(ra) # 800050c4 <argfd>
    return -1;
    800052ee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052f0:	02054363          	bltz	a0,80005316 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052f4:	fd843503          	ld	a0,-40(s0)
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	e34080e7          	jalr	-460(ra) # 8000512c <fdalloc>
    80005300:	84aa                	mv	s1,a0
    return -1;
    80005302:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005304:	00054963          	bltz	a0,80005316 <sys_dup+0x42>
  filedup(f);
    80005308:	fd843503          	ld	a0,-40(s0)
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	36c080e7          	jalr	876(ra) # 80004678 <filedup>
  return fd;
    80005314:	87a6                	mv	a5,s1
}
    80005316:	853e                	mv	a0,a5
    80005318:	70a2                	ld	ra,40(sp)
    8000531a:	7402                	ld	s0,32(sp)
    8000531c:	64e2                	ld	s1,24(sp)
    8000531e:	6145                	addi	sp,sp,48
    80005320:	8082                	ret

0000000080005322 <sys_read>:
{
    80005322:	7179                	addi	sp,sp,-48
    80005324:	f406                	sd	ra,40(sp)
    80005326:	f022                	sd	s0,32(sp)
    80005328:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532a:	fe840613          	addi	a2,s0,-24
    8000532e:	4581                	li	a1,0
    80005330:	4501                	li	a0,0
    80005332:	00000097          	auipc	ra,0x0
    80005336:	d92080e7          	jalr	-622(ra) # 800050c4 <argfd>
    return -1;
    8000533a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533c:	04054163          	bltz	a0,8000537e <sys_read+0x5c>
    80005340:	fe440593          	addi	a1,s0,-28
    80005344:	4509                	li	a0,2
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	87a080e7          	jalr	-1926(ra) # 80002bc0 <argint>
    return -1;
    8000534e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005350:	02054763          	bltz	a0,8000537e <sys_read+0x5c>
    80005354:	fd840593          	addi	a1,s0,-40
    80005358:	4505                	li	a0,1
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	888080e7          	jalr	-1912(ra) # 80002be2 <argaddr>
    return -1;
    80005362:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005364:	00054d63          	bltz	a0,8000537e <sys_read+0x5c>
  return fileread(f, p, n);
    80005368:	fe442603          	lw	a2,-28(s0)
    8000536c:	fd843583          	ld	a1,-40(s0)
    80005370:	fe843503          	ld	a0,-24(s0)
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	490080e7          	jalr	1168(ra) # 80004804 <fileread>
    8000537c:	87aa                	mv	a5,a0
}
    8000537e:	853e                	mv	a0,a5
    80005380:	70a2                	ld	ra,40(sp)
    80005382:	7402                	ld	s0,32(sp)
    80005384:	6145                	addi	sp,sp,48
    80005386:	8082                	ret

0000000080005388 <sys_write>:
{
    80005388:	7179                	addi	sp,sp,-48
    8000538a:	f406                	sd	ra,40(sp)
    8000538c:	f022                	sd	s0,32(sp)
    8000538e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	fe840613          	addi	a2,s0,-24
    80005394:	4581                	li	a1,0
    80005396:	4501                	li	a0,0
    80005398:	00000097          	auipc	ra,0x0
    8000539c:	d2c080e7          	jalr	-724(ra) # 800050c4 <argfd>
    return -1;
    800053a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a2:	04054163          	bltz	a0,800053e4 <sys_write+0x5c>
    800053a6:	fe440593          	addi	a1,s0,-28
    800053aa:	4509                	li	a0,2
    800053ac:	ffffe097          	auipc	ra,0xffffe
    800053b0:	814080e7          	jalr	-2028(ra) # 80002bc0 <argint>
    return -1;
    800053b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b6:	02054763          	bltz	a0,800053e4 <sys_write+0x5c>
    800053ba:	fd840593          	addi	a1,s0,-40
    800053be:	4505                	li	a0,1
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	822080e7          	jalr	-2014(ra) # 80002be2 <argaddr>
    return -1;
    800053c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ca:	00054d63          	bltz	a0,800053e4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053ce:	fe442603          	lw	a2,-28(s0)
    800053d2:	fd843583          	ld	a1,-40(s0)
    800053d6:	fe843503          	ld	a0,-24(s0)
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	4ec080e7          	jalr	1260(ra) # 800048c6 <filewrite>
    800053e2:	87aa                	mv	a5,a0
}
    800053e4:	853e                	mv	a0,a5
    800053e6:	70a2                	ld	ra,40(sp)
    800053e8:	7402                	ld	s0,32(sp)
    800053ea:	6145                	addi	sp,sp,48
    800053ec:	8082                	ret

00000000800053ee <sys_close>:
{
    800053ee:	1101                	addi	sp,sp,-32
    800053f0:	ec06                	sd	ra,24(sp)
    800053f2:	e822                	sd	s0,16(sp)
    800053f4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053f6:	fe040613          	addi	a2,s0,-32
    800053fa:	fec40593          	addi	a1,s0,-20
    800053fe:	4501                	li	a0,0
    80005400:	00000097          	auipc	ra,0x0
    80005404:	cc4080e7          	jalr	-828(ra) # 800050c4 <argfd>
    return -1;
    80005408:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000540a:	02054463          	bltz	a0,80005432 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000540e:	ffffc097          	auipc	ra,0xffffc
    80005412:	584080e7          	jalr	1412(ra) # 80001992 <myproc>
    80005416:	fec42783          	lw	a5,-20(s0)
    8000541a:	07e9                	addi	a5,a5,26
    8000541c:	078e                	slli	a5,a5,0x3
    8000541e:	97aa                	add	a5,a5,a0
    80005420:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005424:	fe043503          	ld	a0,-32(s0)
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	2a2080e7          	jalr	674(ra) # 800046ca <fileclose>
  return 0;
    80005430:	4781                	li	a5,0
}
    80005432:	853e                	mv	a0,a5
    80005434:	60e2                	ld	ra,24(sp)
    80005436:	6442                	ld	s0,16(sp)
    80005438:	6105                	addi	sp,sp,32
    8000543a:	8082                	ret

000000008000543c <sys_fstat>:
{
    8000543c:	1101                	addi	sp,sp,-32
    8000543e:	ec06                	sd	ra,24(sp)
    80005440:	e822                	sd	s0,16(sp)
    80005442:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005444:	fe840613          	addi	a2,s0,-24
    80005448:	4581                	li	a1,0
    8000544a:	4501                	li	a0,0
    8000544c:	00000097          	auipc	ra,0x0
    80005450:	c78080e7          	jalr	-904(ra) # 800050c4 <argfd>
    return -1;
    80005454:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005456:	02054563          	bltz	a0,80005480 <sys_fstat+0x44>
    8000545a:	fe040593          	addi	a1,s0,-32
    8000545e:	4505                	li	a0,1
    80005460:	ffffd097          	auipc	ra,0xffffd
    80005464:	782080e7          	jalr	1922(ra) # 80002be2 <argaddr>
    return -1;
    80005468:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000546a:	00054b63          	bltz	a0,80005480 <sys_fstat+0x44>
  return filestat(f, st);
    8000546e:	fe043583          	ld	a1,-32(s0)
    80005472:	fe843503          	ld	a0,-24(s0)
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	31c080e7          	jalr	796(ra) # 80004792 <filestat>
    8000547e:	87aa                	mv	a5,a0
}
    80005480:	853e                	mv	a0,a5
    80005482:	60e2                	ld	ra,24(sp)
    80005484:	6442                	ld	s0,16(sp)
    80005486:	6105                	addi	sp,sp,32
    80005488:	8082                	ret

000000008000548a <sys_link>:
{
    8000548a:	7169                	addi	sp,sp,-304
    8000548c:	f606                	sd	ra,296(sp)
    8000548e:	f222                	sd	s0,288(sp)
    80005490:	ee26                	sd	s1,280(sp)
    80005492:	ea4a                	sd	s2,272(sp)
    80005494:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005496:	08000613          	li	a2,128
    8000549a:	ed040593          	addi	a1,s0,-304
    8000549e:	4501                	li	a0,0
    800054a0:	ffffd097          	auipc	ra,0xffffd
    800054a4:	764080e7          	jalr	1892(ra) # 80002c04 <argstr>
    return -1;
    800054a8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054aa:	10054e63          	bltz	a0,800055c6 <sys_link+0x13c>
    800054ae:	08000613          	li	a2,128
    800054b2:	f5040593          	addi	a1,s0,-176
    800054b6:	4505                	li	a0,1
    800054b8:	ffffd097          	auipc	ra,0xffffd
    800054bc:	74c080e7          	jalr	1868(ra) # 80002c04 <argstr>
    return -1;
    800054c0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c2:	10054263          	bltz	a0,800055c6 <sys_link+0x13c>
  begin_op();
    800054c6:	fffff097          	auipc	ra,0xfffff
    800054ca:	d38080e7          	jalr	-712(ra) # 800041fe <begin_op>
  if((ip = namei(old)) == 0){
    800054ce:	ed040513          	addi	a0,s0,-304
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	b0c080e7          	jalr	-1268(ra) # 80003fde <namei>
    800054da:	84aa                	mv	s1,a0
    800054dc:	c551                	beqz	a0,80005568 <sys_link+0xde>
  ilock(ip);
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	34a080e7          	jalr	842(ra) # 80003828 <ilock>
  if(ip->type == T_DIR){
    800054e6:	04449703          	lh	a4,68(s1)
    800054ea:	4785                	li	a5,1
    800054ec:	08f70463          	beq	a4,a5,80005574 <sys_link+0xea>
  ip->nlink++;
    800054f0:	04a4d783          	lhu	a5,74(s1)
    800054f4:	2785                	addiw	a5,a5,1
    800054f6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	262080e7          	jalr	610(ra) # 8000375e <iupdate>
  iunlock(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	3e4080e7          	jalr	996(ra) # 800038ea <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000550e:	fd040593          	addi	a1,s0,-48
    80005512:	f5040513          	addi	a0,s0,-176
    80005516:	fffff097          	auipc	ra,0xfffff
    8000551a:	ae6080e7          	jalr	-1306(ra) # 80003ffc <nameiparent>
    8000551e:	892a                	mv	s2,a0
    80005520:	c935                	beqz	a0,80005594 <sys_link+0x10a>
  ilock(dp);
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	306080e7          	jalr	774(ra) # 80003828 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000552a:	00092703          	lw	a4,0(s2)
    8000552e:	409c                	lw	a5,0(s1)
    80005530:	04f71d63          	bne	a4,a5,8000558a <sys_link+0x100>
    80005534:	40d0                	lw	a2,4(s1)
    80005536:	fd040593          	addi	a1,s0,-48
    8000553a:	854a                	mv	a0,s2
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	9e0080e7          	jalr	-1568(ra) # 80003f1c <dirlink>
    80005544:	04054363          	bltz	a0,8000558a <sys_link+0x100>
  iunlockput(dp);
    80005548:	854a                	mv	a0,s2
    8000554a:	ffffe097          	auipc	ra,0xffffe
    8000554e:	540080e7          	jalr	1344(ra) # 80003a8a <iunlockput>
  iput(ip);
    80005552:	8526                	mv	a0,s1
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	48e080e7          	jalr	1166(ra) # 800039e2 <iput>
  end_op();
    8000555c:	fffff097          	auipc	ra,0xfffff
    80005560:	d22080e7          	jalr	-734(ra) # 8000427e <end_op>
  return 0;
    80005564:	4781                	li	a5,0
    80005566:	a085                	j	800055c6 <sys_link+0x13c>
    end_op();
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	d16080e7          	jalr	-746(ra) # 8000427e <end_op>
    return -1;
    80005570:	57fd                	li	a5,-1
    80005572:	a891                	j	800055c6 <sys_link+0x13c>
    iunlockput(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	514080e7          	jalr	1300(ra) # 80003a8a <iunlockput>
    end_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	d00080e7          	jalr	-768(ra) # 8000427e <end_op>
    return -1;
    80005586:	57fd                	li	a5,-1
    80005588:	a83d                	j	800055c6 <sys_link+0x13c>
    iunlockput(dp);
    8000558a:	854a                	mv	a0,s2
    8000558c:	ffffe097          	auipc	ra,0xffffe
    80005590:	4fe080e7          	jalr	1278(ra) # 80003a8a <iunlockput>
  ilock(ip);
    80005594:	8526                	mv	a0,s1
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	292080e7          	jalr	658(ra) # 80003828 <ilock>
  ip->nlink--;
    8000559e:	04a4d783          	lhu	a5,74(s1)
    800055a2:	37fd                	addiw	a5,a5,-1
    800055a4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055a8:	8526                	mv	a0,s1
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	1b4080e7          	jalr	436(ra) # 8000375e <iupdate>
  iunlockput(ip);
    800055b2:	8526                	mv	a0,s1
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	4d6080e7          	jalr	1238(ra) # 80003a8a <iunlockput>
  end_op();
    800055bc:	fffff097          	auipc	ra,0xfffff
    800055c0:	cc2080e7          	jalr	-830(ra) # 8000427e <end_op>
  return -1;
    800055c4:	57fd                	li	a5,-1
}
    800055c6:	853e                	mv	a0,a5
    800055c8:	70b2                	ld	ra,296(sp)
    800055ca:	7412                	ld	s0,288(sp)
    800055cc:	64f2                	ld	s1,280(sp)
    800055ce:	6952                	ld	s2,272(sp)
    800055d0:	6155                	addi	sp,sp,304
    800055d2:	8082                	ret

00000000800055d4 <sys_unlink>:
{
    800055d4:	7151                	addi	sp,sp,-240
    800055d6:	f586                	sd	ra,232(sp)
    800055d8:	f1a2                	sd	s0,224(sp)
    800055da:	eda6                	sd	s1,216(sp)
    800055dc:	e9ca                	sd	s2,208(sp)
    800055de:	e5ce                	sd	s3,200(sp)
    800055e0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055e2:	08000613          	li	a2,128
    800055e6:	f3040593          	addi	a1,s0,-208
    800055ea:	4501                	li	a0,0
    800055ec:	ffffd097          	auipc	ra,0xffffd
    800055f0:	618080e7          	jalr	1560(ra) # 80002c04 <argstr>
    800055f4:	18054163          	bltz	a0,80005776 <sys_unlink+0x1a2>
  begin_op();
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	c06080e7          	jalr	-1018(ra) # 800041fe <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005600:	fb040593          	addi	a1,s0,-80
    80005604:	f3040513          	addi	a0,s0,-208
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	9f4080e7          	jalr	-1548(ra) # 80003ffc <nameiparent>
    80005610:	84aa                	mv	s1,a0
    80005612:	c979                	beqz	a0,800056e8 <sys_unlink+0x114>
  ilock(dp);
    80005614:	ffffe097          	auipc	ra,0xffffe
    80005618:	214080e7          	jalr	532(ra) # 80003828 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000561c:	00003597          	auipc	a1,0x3
    80005620:	30458593          	addi	a1,a1,772 # 80008920 <syscalls_str+0x2b8>
    80005624:	fb040513          	addi	a0,s0,-80
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	6ca080e7          	jalr	1738(ra) # 80003cf2 <namecmp>
    80005630:	14050a63          	beqz	a0,80005784 <sys_unlink+0x1b0>
    80005634:	00003597          	auipc	a1,0x3
    80005638:	2f458593          	addi	a1,a1,756 # 80008928 <syscalls_str+0x2c0>
    8000563c:	fb040513          	addi	a0,s0,-80
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	6b2080e7          	jalr	1714(ra) # 80003cf2 <namecmp>
    80005648:	12050e63          	beqz	a0,80005784 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000564c:	f2c40613          	addi	a2,s0,-212
    80005650:	fb040593          	addi	a1,s0,-80
    80005654:	8526                	mv	a0,s1
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	6b6080e7          	jalr	1718(ra) # 80003d0c <dirlookup>
    8000565e:	892a                	mv	s2,a0
    80005660:	12050263          	beqz	a0,80005784 <sys_unlink+0x1b0>
  ilock(ip);
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	1c4080e7          	jalr	452(ra) # 80003828 <ilock>
  if(ip->nlink < 1)
    8000566c:	04a91783          	lh	a5,74(s2)
    80005670:	08f05263          	blez	a5,800056f4 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005674:	04491703          	lh	a4,68(s2)
    80005678:	4785                	li	a5,1
    8000567a:	08f70563          	beq	a4,a5,80005704 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000567e:	4641                	li	a2,16
    80005680:	4581                	li	a1,0
    80005682:	fc040513          	addi	a0,s0,-64
    80005686:	ffffb097          	auipc	ra,0xffffb
    8000568a:	638080e7          	jalr	1592(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000568e:	4741                	li	a4,16
    80005690:	f2c42683          	lw	a3,-212(s0)
    80005694:	fc040613          	addi	a2,s0,-64
    80005698:	4581                	li	a1,0
    8000569a:	8526                	mv	a0,s1
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	538080e7          	jalr	1336(ra) # 80003bd4 <writei>
    800056a4:	47c1                	li	a5,16
    800056a6:	0af51563          	bne	a0,a5,80005750 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056aa:	04491703          	lh	a4,68(s2)
    800056ae:	4785                	li	a5,1
    800056b0:	0af70863          	beq	a4,a5,80005760 <sys_unlink+0x18c>
  iunlockput(dp);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	3d4080e7          	jalr	980(ra) # 80003a8a <iunlockput>
  ip->nlink--;
    800056be:	04a95783          	lhu	a5,74(s2)
    800056c2:	37fd                	addiw	a5,a5,-1
    800056c4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056c8:	854a                	mv	a0,s2
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	094080e7          	jalr	148(ra) # 8000375e <iupdate>
  iunlockput(ip);
    800056d2:	854a                	mv	a0,s2
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	3b6080e7          	jalr	950(ra) # 80003a8a <iunlockput>
  end_op();
    800056dc:	fffff097          	auipc	ra,0xfffff
    800056e0:	ba2080e7          	jalr	-1118(ra) # 8000427e <end_op>
  return 0;
    800056e4:	4501                	li	a0,0
    800056e6:	a84d                	j	80005798 <sys_unlink+0x1c4>
    end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	b96080e7          	jalr	-1130(ra) # 8000427e <end_op>
    return -1;
    800056f0:	557d                	li	a0,-1
    800056f2:	a05d                	j	80005798 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056f4:	00003517          	auipc	a0,0x3
    800056f8:	25c50513          	addi	a0,a0,604 # 80008950 <syscalls_str+0x2e8>
    800056fc:	ffffb097          	auipc	ra,0xffffb
    80005700:	e2e080e7          	jalr	-466(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005704:	04c92703          	lw	a4,76(s2)
    80005708:	02000793          	li	a5,32
    8000570c:	f6e7f9e3          	bgeu	a5,a4,8000567e <sys_unlink+0xaa>
    80005710:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005714:	4741                	li	a4,16
    80005716:	86ce                	mv	a3,s3
    80005718:	f1840613          	addi	a2,s0,-232
    8000571c:	4581                	li	a1,0
    8000571e:	854a                	mv	a0,s2
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	3bc080e7          	jalr	956(ra) # 80003adc <readi>
    80005728:	47c1                	li	a5,16
    8000572a:	00f51b63          	bne	a0,a5,80005740 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000572e:	f1845783          	lhu	a5,-232(s0)
    80005732:	e7a1                	bnez	a5,8000577a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005734:	29c1                	addiw	s3,s3,16
    80005736:	04c92783          	lw	a5,76(s2)
    8000573a:	fcf9ede3          	bltu	s3,a5,80005714 <sys_unlink+0x140>
    8000573e:	b781                	j	8000567e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005740:	00003517          	auipc	a0,0x3
    80005744:	22850513          	addi	a0,a0,552 # 80008968 <syscalls_str+0x300>
    80005748:	ffffb097          	auipc	ra,0xffffb
    8000574c:	de2080e7          	jalr	-542(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005750:	00003517          	auipc	a0,0x3
    80005754:	23050513          	addi	a0,a0,560 # 80008980 <syscalls_str+0x318>
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	dd2080e7          	jalr	-558(ra) # 8000052a <panic>
    dp->nlink--;
    80005760:	04a4d783          	lhu	a5,74(s1)
    80005764:	37fd                	addiw	a5,a5,-1
    80005766:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000576a:	8526                	mv	a0,s1
    8000576c:	ffffe097          	auipc	ra,0xffffe
    80005770:	ff2080e7          	jalr	-14(ra) # 8000375e <iupdate>
    80005774:	b781                	j	800056b4 <sys_unlink+0xe0>
    return -1;
    80005776:	557d                	li	a0,-1
    80005778:	a005                	j	80005798 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000577a:	854a                	mv	a0,s2
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	30e080e7          	jalr	782(ra) # 80003a8a <iunlockput>
  iunlockput(dp);
    80005784:	8526                	mv	a0,s1
    80005786:	ffffe097          	auipc	ra,0xffffe
    8000578a:	304080e7          	jalr	772(ra) # 80003a8a <iunlockput>
  end_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	af0080e7          	jalr	-1296(ra) # 8000427e <end_op>
  return -1;
    80005796:	557d                	li	a0,-1
}
    80005798:	70ae                	ld	ra,232(sp)
    8000579a:	740e                	ld	s0,224(sp)
    8000579c:	64ee                	ld	s1,216(sp)
    8000579e:	694e                	ld	s2,208(sp)
    800057a0:	69ae                	ld	s3,200(sp)
    800057a2:	616d                	addi	sp,sp,240
    800057a4:	8082                	ret

00000000800057a6 <sys_open>:

uint64
sys_open(void)
{
    800057a6:	7131                	addi	sp,sp,-192
    800057a8:	fd06                	sd	ra,184(sp)
    800057aa:	f922                	sd	s0,176(sp)
    800057ac:	f526                	sd	s1,168(sp)
    800057ae:	f14a                	sd	s2,160(sp)
    800057b0:	ed4e                	sd	s3,152(sp)
    800057b2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057b4:	08000613          	li	a2,128
    800057b8:	f5040593          	addi	a1,s0,-176
    800057bc:	4501                	li	a0,0
    800057be:	ffffd097          	auipc	ra,0xffffd
    800057c2:	446080e7          	jalr	1094(ra) # 80002c04 <argstr>
    return -1;
    800057c6:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057c8:	0c054163          	bltz	a0,8000588a <sys_open+0xe4>
    800057cc:	f4c40593          	addi	a1,s0,-180
    800057d0:	4505                	li	a0,1
    800057d2:	ffffd097          	auipc	ra,0xffffd
    800057d6:	3ee080e7          	jalr	1006(ra) # 80002bc0 <argint>
    800057da:	0a054863          	bltz	a0,8000588a <sys_open+0xe4>

  begin_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	a20080e7          	jalr	-1504(ra) # 800041fe <begin_op>

  if(omode & O_CREATE){
    800057e6:	f4c42783          	lw	a5,-180(s0)
    800057ea:	2007f793          	andi	a5,a5,512
    800057ee:	cbdd                	beqz	a5,800058a4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057f0:	4681                	li	a3,0
    800057f2:	4601                	li	a2,0
    800057f4:	4589                	li	a1,2
    800057f6:	f5040513          	addi	a0,s0,-176
    800057fa:	00000097          	auipc	ra,0x0
    800057fe:	974080e7          	jalr	-1676(ra) # 8000516e <create>
    80005802:	892a                	mv	s2,a0
    if(ip == 0){
    80005804:	c959                	beqz	a0,8000589a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005806:	04491703          	lh	a4,68(s2)
    8000580a:	478d                	li	a5,3
    8000580c:	00f71763          	bne	a4,a5,8000581a <sys_open+0x74>
    80005810:	04695703          	lhu	a4,70(s2)
    80005814:	47a5                	li	a5,9
    80005816:	0ce7ec63          	bltu	a5,a4,800058ee <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	df4080e7          	jalr	-524(ra) # 8000460e <filealloc>
    80005822:	89aa                	mv	s3,a0
    80005824:	10050263          	beqz	a0,80005928 <sys_open+0x182>
    80005828:	00000097          	auipc	ra,0x0
    8000582c:	904080e7          	jalr	-1788(ra) # 8000512c <fdalloc>
    80005830:	84aa                	mv	s1,a0
    80005832:	0e054663          	bltz	a0,8000591e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005836:	04491703          	lh	a4,68(s2)
    8000583a:	478d                	li	a5,3
    8000583c:	0cf70463          	beq	a4,a5,80005904 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005840:	4789                	li	a5,2
    80005842:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005846:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000584a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000584e:	f4c42783          	lw	a5,-180(s0)
    80005852:	0017c713          	xori	a4,a5,1
    80005856:	8b05                	andi	a4,a4,1
    80005858:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000585c:	0037f713          	andi	a4,a5,3
    80005860:	00e03733          	snez	a4,a4
    80005864:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005868:	4007f793          	andi	a5,a5,1024
    8000586c:	c791                	beqz	a5,80005878 <sys_open+0xd2>
    8000586e:	04491703          	lh	a4,68(s2)
    80005872:	4789                	li	a5,2
    80005874:	08f70f63          	beq	a4,a5,80005912 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005878:	854a                	mv	a0,s2
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	070080e7          	jalr	112(ra) # 800038ea <iunlock>
  end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	9fc080e7          	jalr	-1540(ra) # 8000427e <end_op>

  return fd;
}
    8000588a:	8526                	mv	a0,s1
    8000588c:	70ea                	ld	ra,184(sp)
    8000588e:	744a                	ld	s0,176(sp)
    80005890:	74aa                	ld	s1,168(sp)
    80005892:	790a                	ld	s2,160(sp)
    80005894:	69ea                	ld	s3,152(sp)
    80005896:	6129                	addi	sp,sp,192
    80005898:	8082                	ret
      end_op();
    8000589a:	fffff097          	auipc	ra,0xfffff
    8000589e:	9e4080e7          	jalr	-1564(ra) # 8000427e <end_op>
      return -1;
    800058a2:	b7e5                	j	8000588a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058a4:	f5040513          	addi	a0,s0,-176
    800058a8:	ffffe097          	auipc	ra,0xffffe
    800058ac:	736080e7          	jalr	1846(ra) # 80003fde <namei>
    800058b0:	892a                	mv	s2,a0
    800058b2:	c905                	beqz	a0,800058e2 <sys_open+0x13c>
    ilock(ip);
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	f74080e7          	jalr	-140(ra) # 80003828 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058bc:	04491703          	lh	a4,68(s2)
    800058c0:	4785                	li	a5,1
    800058c2:	f4f712e3          	bne	a4,a5,80005806 <sys_open+0x60>
    800058c6:	f4c42783          	lw	a5,-180(s0)
    800058ca:	dba1                	beqz	a5,8000581a <sys_open+0x74>
      iunlockput(ip);
    800058cc:	854a                	mv	a0,s2
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	1bc080e7          	jalr	444(ra) # 80003a8a <iunlockput>
      end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	9a8080e7          	jalr	-1624(ra) # 8000427e <end_op>
      return -1;
    800058de:	54fd                	li	s1,-1
    800058e0:	b76d                	j	8000588a <sys_open+0xe4>
      end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	99c080e7          	jalr	-1636(ra) # 8000427e <end_op>
      return -1;
    800058ea:	54fd                	li	s1,-1
    800058ec:	bf79                	j	8000588a <sys_open+0xe4>
    iunlockput(ip);
    800058ee:	854a                	mv	a0,s2
    800058f0:	ffffe097          	auipc	ra,0xffffe
    800058f4:	19a080e7          	jalr	410(ra) # 80003a8a <iunlockput>
    end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	986080e7          	jalr	-1658(ra) # 8000427e <end_op>
    return -1;
    80005900:	54fd                	li	s1,-1
    80005902:	b761                	j	8000588a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005904:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005908:	04691783          	lh	a5,70(s2)
    8000590c:	02f99223          	sh	a5,36(s3)
    80005910:	bf2d                	j	8000584a <sys_open+0xa4>
    itrunc(ip);
    80005912:	854a                	mv	a0,s2
    80005914:	ffffe097          	auipc	ra,0xffffe
    80005918:	022080e7          	jalr	34(ra) # 80003936 <itrunc>
    8000591c:	bfb1                	j	80005878 <sys_open+0xd2>
      fileclose(f);
    8000591e:	854e                	mv	a0,s3
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	daa080e7          	jalr	-598(ra) # 800046ca <fileclose>
    iunlockput(ip);
    80005928:	854a                	mv	a0,s2
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	160080e7          	jalr	352(ra) # 80003a8a <iunlockput>
    end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	94c080e7          	jalr	-1716(ra) # 8000427e <end_op>
    return -1;
    8000593a:	54fd                	li	s1,-1
    8000593c:	b7b9                	j	8000588a <sys_open+0xe4>

000000008000593e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000593e:	7175                	addi	sp,sp,-144
    80005940:	e506                	sd	ra,136(sp)
    80005942:	e122                	sd	s0,128(sp)
    80005944:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	8b8080e7          	jalr	-1864(ra) # 800041fe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000594e:	08000613          	li	a2,128
    80005952:	f7040593          	addi	a1,s0,-144
    80005956:	4501                	li	a0,0
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	2ac080e7          	jalr	684(ra) # 80002c04 <argstr>
    80005960:	02054963          	bltz	a0,80005992 <sys_mkdir+0x54>
    80005964:	4681                	li	a3,0
    80005966:	4601                	li	a2,0
    80005968:	4585                	li	a1,1
    8000596a:	f7040513          	addi	a0,s0,-144
    8000596e:	00000097          	auipc	ra,0x0
    80005972:	800080e7          	jalr	-2048(ra) # 8000516e <create>
    80005976:	cd11                	beqz	a0,80005992 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005978:	ffffe097          	auipc	ra,0xffffe
    8000597c:	112080e7          	jalr	274(ra) # 80003a8a <iunlockput>
  end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	8fe080e7          	jalr	-1794(ra) # 8000427e <end_op>
  return 0;
    80005988:	4501                	li	a0,0
}
    8000598a:	60aa                	ld	ra,136(sp)
    8000598c:	640a                	ld	s0,128(sp)
    8000598e:	6149                	addi	sp,sp,144
    80005990:	8082                	ret
    end_op();
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	8ec080e7          	jalr	-1812(ra) # 8000427e <end_op>
    return -1;
    8000599a:	557d                	li	a0,-1
    8000599c:	b7fd                	j	8000598a <sys_mkdir+0x4c>

000000008000599e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000599e:	7135                	addi	sp,sp,-160
    800059a0:	ed06                	sd	ra,152(sp)
    800059a2:	e922                	sd	s0,144(sp)
    800059a4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	858080e7          	jalr	-1960(ra) # 800041fe <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ae:	08000613          	li	a2,128
    800059b2:	f7040593          	addi	a1,s0,-144
    800059b6:	4501                	li	a0,0
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	24c080e7          	jalr	588(ra) # 80002c04 <argstr>
    800059c0:	04054a63          	bltz	a0,80005a14 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059c4:	f6c40593          	addi	a1,s0,-148
    800059c8:	4505                	li	a0,1
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	1f6080e7          	jalr	502(ra) # 80002bc0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059d2:	04054163          	bltz	a0,80005a14 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059d6:	f6840593          	addi	a1,s0,-152
    800059da:	4509                	li	a0,2
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	1e4080e7          	jalr	484(ra) # 80002bc0 <argint>
     argint(1, &major) < 0 ||
    800059e4:	02054863          	bltz	a0,80005a14 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059e8:	f6841683          	lh	a3,-152(s0)
    800059ec:	f6c41603          	lh	a2,-148(s0)
    800059f0:	458d                	li	a1,3
    800059f2:	f7040513          	addi	a0,s0,-144
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	778080e7          	jalr	1912(ra) # 8000516e <create>
     argint(2, &minor) < 0 ||
    800059fe:	c919                	beqz	a0,80005a14 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	08a080e7          	jalr	138(ra) # 80003a8a <iunlockput>
  end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	876080e7          	jalr	-1930(ra) # 8000427e <end_op>
  return 0;
    80005a10:	4501                	li	a0,0
    80005a12:	a031                	j	80005a1e <sys_mknod+0x80>
    end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	86a080e7          	jalr	-1942(ra) # 8000427e <end_op>
    return -1;
    80005a1c:	557d                	li	a0,-1
}
    80005a1e:	60ea                	ld	ra,152(sp)
    80005a20:	644a                	ld	s0,144(sp)
    80005a22:	610d                	addi	sp,sp,160
    80005a24:	8082                	ret

0000000080005a26 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a26:	7135                	addi	sp,sp,-160
    80005a28:	ed06                	sd	ra,152(sp)
    80005a2a:	e922                	sd	s0,144(sp)
    80005a2c:	e526                	sd	s1,136(sp)
    80005a2e:	e14a                	sd	s2,128(sp)
    80005a30:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a32:	ffffc097          	auipc	ra,0xffffc
    80005a36:	f60080e7          	jalr	-160(ra) # 80001992 <myproc>
    80005a3a:	892a                	mv	s2,a0
  
  begin_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7c2080e7          	jalr	1986(ra) # 800041fe <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a44:	08000613          	li	a2,128
    80005a48:	f6040593          	addi	a1,s0,-160
    80005a4c:	4501                	li	a0,0
    80005a4e:	ffffd097          	auipc	ra,0xffffd
    80005a52:	1b6080e7          	jalr	438(ra) # 80002c04 <argstr>
    80005a56:	04054b63          	bltz	a0,80005aac <sys_chdir+0x86>
    80005a5a:	f6040513          	addi	a0,s0,-160
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	580080e7          	jalr	1408(ra) # 80003fde <namei>
    80005a66:	84aa                	mv	s1,a0
    80005a68:	c131                	beqz	a0,80005aac <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	dbe080e7          	jalr	-578(ra) # 80003828 <ilock>
  if(ip->type != T_DIR){
    80005a72:	04449703          	lh	a4,68(s1)
    80005a76:	4785                	li	a5,1
    80005a78:	04f71063          	bne	a4,a5,80005ab8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a7c:	8526                	mv	a0,s1
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	e6c080e7          	jalr	-404(ra) # 800038ea <iunlock>
  iput(p->cwd);
    80005a86:	15093503          	ld	a0,336(s2)
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	f58080e7          	jalr	-168(ra) # 800039e2 <iput>
  end_op();
    80005a92:	ffffe097          	auipc	ra,0xffffe
    80005a96:	7ec080e7          	jalr	2028(ra) # 8000427e <end_op>
  p->cwd = ip;
    80005a9a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a9e:	4501                	li	a0,0
}
    80005aa0:	60ea                	ld	ra,152(sp)
    80005aa2:	644a                	ld	s0,144(sp)
    80005aa4:	64aa                	ld	s1,136(sp)
    80005aa6:	690a                	ld	s2,128(sp)
    80005aa8:	610d                	addi	sp,sp,160
    80005aaa:	8082                	ret
    end_op();
    80005aac:	ffffe097          	auipc	ra,0xffffe
    80005ab0:	7d2080e7          	jalr	2002(ra) # 8000427e <end_op>
    return -1;
    80005ab4:	557d                	li	a0,-1
    80005ab6:	b7ed                	j	80005aa0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ab8:	8526                	mv	a0,s1
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	fd0080e7          	jalr	-48(ra) # 80003a8a <iunlockput>
    end_op();
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	7bc080e7          	jalr	1980(ra) # 8000427e <end_op>
    return -1;
    80005aca:	557d                	li	a0,-1
    80005acc:	bfd1                	j	80005aa0 <sys_chdir+0x7a>

0000000080005ace <sys_exec>:

uint64
sys_exec(void)
{
    80005ace:	7145                	addi	sp,sp,-464
    80005ad0:	e786                	sd	ra,456(sp)
    80005ad2:	e3a2                	sd	s0,448(sp)
    80005ad4:	ff26                	sd	s1,440(sp)
    80005ad6:	fb4a                	sd	s2,432(sp)
    80005ad8:	f74e                	sd	s3,424(sp)
    80005ada:	f352                	sd	s4,416(sp)
    80005adc:	ef56                	sd	s5,408(sp)
    80005ade:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae0:	08000613          	li	a2,128
    80005ae4:	f4040593          	addi	a1,s0,-192
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	11a080e7          	jalr	282(ra) # 80002c04 <argstr>
    return -1;
    80005af2:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005af4:	0c054a63          	bltz	a0,80005bc8 <sys_exec+0xfa>
    80005af8:	e3840593          	addi	a1,s0,-456
    80005afc:	4505                	li	a0,1
    80005afe:	ffffd097          	auipc	ra,0xffffd
    80005b02:	0e4080e7          	jalr	228(ra) # 80002be2 <argaddr>
    80005b06:	0c054163          	bltz	a0,80005bc8 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b0a:	10000613          	li	a2,256
    80005b0e:	4581                	li	a1,0
    80005b10:	e4040513          	addi	a0,s0,-448
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	1aa080e7          	jalr	426(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b1c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b20:	89a6                	mv	s3,s1
    80005b22:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b24:	02000a13          	li	s4,32
    80005b28:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b2c:	00391793          	slli	a5,s2,0x3
    80005b30:	e3040593          	addi	a1,s0,-464
    80005b34:	e3843503          	ld	a0,-456(s0)
    80005b38:	953e                	add	a0,a0,a5
    80005b3a:	ffffd097          	auipc	ra,0xffffd
    80005b3e:	fec080e7          	jalr	-20(ra) # 80002b26 <fetchaddr>
    80005b42:	02054a63          	bltz	a0,80005b76 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b46:	e3043783          	ld	a5,-464(s0)
    80005b4a:	c3b9                	beqz	a5,80005b90 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	f86080e7          	jalr	-122(ra) # 80000ad2 <kalloc>
    80005b54:	85aa                	mv	a1,a0
    80005b56:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b5a:	cd11                	beqz	a0,80005b76 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b5c:	6605                	lui	a2,0x1
    80005b5e:	e3043503          	ld	a0,-464(s0)
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	016080e7          	jalr	22(ra) # 80002b78 <fetchstr>
    80005b6a:	00054663          	bltz	a0,80005b76 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b6e:	0905                	addi	s2,s2,1
    80005b70:	09a1                	addi	s3,s3,8
    80005b72:	fb491be3          	bne	s2,s4,80005b28 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b76:	10048913          	addi	s2,s1,256
    80005b7a:	6088                	ld	a0,0(s1)
    80005b7c:	c529                	beqz	a0,80005bc6 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	e58080e7          	jalr	-424(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	04a1                	addi	s1,s1,8
    80005b88:	ff2499e3          	bne	s1,s2,80005b7a <sys_exec+0xac>
  return -1;
    80005b8c:	597d                	li	s2,-1
    80005b8e:	a82d                	j	80005bc8 <sys_exec+0xfa>
      argv[i] = 0;
    80005b90:	0a8e                	slli	s5,s5,0x3
    80005b92:	fc040793          	addi	a5,s0,-64
    80005b96:	9abe                	add	s5,s5,a5
    80005b98:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005b9c:	e4040593          	addi	a1,s0,-448
    80005ba0:	f4040513          	addi	a0,s0,-192
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	178080e7          	jalr	376(ra) # 80004d1c <exec>
    80005bac:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bae:	10048993          	addi	s3,s1,256
    80005bb2:	6088                	ld	a0,0(s1)
    80005bb4:	c911                	beqz	a0,80005bc8 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bb6:	ffffb097          	auipc	ra,0xffffb
    80005bba:	e20080e7          	jalr	-480(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbe:	04a1                	addi	s1,s1,8
    80005bc0:	ff3499e3          	bne	s1,s3,80005bb2 <sys_exec+0xe4>
    80005bc4:	a011                	j	80005bc8 <sys_exec+0xfa>
  return -1;
    80005bc6:	597d                	li	s2,-1
}
    80005bc8:	854a                	mv	a0,s2
    80005bca:	60be                	ld	ra,456(sp)
    80005bcc:	641e                	ld	s0,448(sp)
    80005bce:	74fa                	ld	s1,440(sp)
    80005bd0:	795a                	ld	s2,432(sp)
    80005bd2:	79ba                	ld	s3,424(sp)
    80005bd4:	7a1a                	ld	s4,416(sp)
    80005bd6:	6afa                	ld	s5,408(sp)
    80005bd8:	6179                	addi	sp,sp,464
    80005bda:	8082                	ret

0000000080005bdc <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bdc:	7139                	addi	sp,sp,-64
    80005bde:	fc06                	sd	ra,56(sp)
    80005be0:	f822                	sd	s0,48(sp)
    80005be2:	f426                	sd	s1,40(sp)
    80005be4:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005be6:	ffffc097          	auipc	ra,0xffffc
    80005bea:	dac080e7          	jalr	-596(ra) # 80001992 <myproc>
    80005bee:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bf0:	fd840593          	addi	a1,s0,-40
    80005bf4:	4501                	li	a0,0
    80005bf6:	ffffd097          	auipc	ra,0xffffd
    80005bfa:	fec080e7          	jalr	-20(ra) # 80002be2 <argaddr>
    return -1;
    80005bfe:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c00:	0e054063          	bltz	a0,80005ce0 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c04:	fc840593          	addi	a1,s0,-56
    80005c08:	fd040513          	addi	a0,s0,-48
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	dee080e7          	jalr	-530(ra) # 800049fa <pipealloc>
    return -1;
    80005c14:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c16:	0c054563          	bltz	a0,80005ce0 <sys_pipe+0x104>
  fd0 = -1;
    80005c1a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c1e:	fd043503          	ld	a0,-48(s0)
    80005c22:	fffff097          	auipc	ra,0xfffff
    80005c26:	50a080e7          	jalr	1290(ra) # 8000512c <fdalloc>
    80005c2a:	fca42223          	sw	a0,-60(s0)
    80005c2e:	08054c63          	bltz	a0,80005cc6 <sys_pipe+0xea>
    80005c32:	fc843503          	ld	a0,-56(s0)
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	4f6080e7          	jalr	1270(ra) # 8000512c <fdalloc>
    80005c3e:	fca42023          	sw	a0,-64(s0)
    80005c42:	06054863          	bltz	a0,80005cb2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c46:	4691                	li	a3,4
    80005c48:	fc440613          	addi	a2,s0,-60
    80005c4c:	fd843583          	ld	a1,-40(s0)
    80005c50:	68a8                	ld	a0,80(s1)
    80005c52:	ffffc097          	auipc	ra,0xffffc
    80005c56:	9ec080e7          	jalr	-1556(ra) # 8000163e <copyout>
    80005c5a:	02054063          	bltz	a0,80005c7a <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c5e:	4691                	li	a3,4
    80005c60:	fc040613          	addi	a2,s0,-64
    80005c64:	fd843583          	ld	a1,-40(s0)
    80005c68:	0591                	addi	a1,a1,4
    80005c6a:	68a8                	ld	a0,80(s1)
    80005c6c:	ffffc097          	auipc	ra,0xffffc
    80005c70:	9d2080e7          	jalr	-1582(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c74:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c76:	06055563          	bgez	a0,80005ce0 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c7a:	fc442783          	lw	a5,-60(s0)
    80005c7e:	07e9                	addi	a5,a5,26
    80005c80:	078e                	slli	a5,a5,0x3
    80005c82:	97a6                	add	a5,a5,s1
    80005c84:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c88:	fc042503          	lw	a0,-64(s0)
    80005c8c:	0569                	addi	a0,a0,26
    80005c8e:	050e                	slli	a0,a0,0x3
    80005c90:	9526                	add	a0,a0,s1
    80005c92:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c96:	fd043503          	ld	a0,-48(s0)
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	a30080e7          	jalr	-1488(ra) # 800046ca <fileclose>
    fileclose(wf);
    80005ca2:	fc843503          	ld	a0,-56(s0)
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	a24080e7          	jalr	-1500(ra) # 800046ca <fileclose>
    return -1;
    80005cae:	57fd                	li	a5,-1
    80005cb0:	a805                	j	80005ce0 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cb2:	fc442783          	lw	a5,-60(s0)
    80005cb6:	0007c863          	bltz	a5,80005cc6 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005cba:	01a78513          	addi	a0,a5,26
    80005cbe:	050e                	slli	a0,a0,0x3
    80005cc0:	9526                	add	a0,a0,s1
    80005cc2:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cc6:	fd043503          	ld	a0,-48(s0)
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	a00080e7          	jalr	-1536(ra) # 800046ca <fileclose>
    fileclose(wf);
    80005cd2:	fc843503          	ld	a0,-56(s0)
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	9f4080e7          	jalr	-1548(ra) # 800046ca <fileclose>
    return -1;
    80005cde:	57fd                	li	a5,-1
}
    80005ce0:	853e                	mv	a0,a5
    80005ce2:	70e2                	ld	ra,56(sp)
    80005ce4:	7442                	ld	s0,48(sp)
    80005ce6:	74a2                	ld	s1,40(sp)
    80005ce8:	6121                	addi	sp,sp,64
    80005cea:	8082                	ret
    80005cec:	0000                	unimp
	...

0000000080005cf0 <kernelvec>:
    80005cf0:	7111                	addi	sp,sp,-256
    80005cf2:	e006                	sd	ra,0(sp)
    80005cf4:	e40a                	sd	sp,8(sp)
    80005cf6:	e80e                	sd	gp,16(sp)
    80005cf8:	ec12                	sd	tp,24(sp)
    80005cfa:	f016                	sd	t0,32(sp)
    80005cfc:	f41a                	sd	t1,40(sp)
    80005cfe:	f81e                	sd	t2,48(sp)
    80005d00:	fc22                	sd	s0,56(sp)
    80005d02:	e0a6                	sd	s1,64(sp)
    80005d04:	e4aa                	sd	a0,72(sp)
    80005d06:	e8ae                	sd	a1,80(sp)
    80005d08:	ecb2                	sd	a2,88(sp)
    80005d0a:	f0b6                	sd	a3,96(sp)
    80005d0c:	f4ba                	sd	a4,104(sp)
    80005d0e:	f8be                	sd	a5,112(sp)
    80005d10:	fcc2                	sd	a6,120(sp)
    80005d12:	e146                	sd	a7,128(sp)
    80005d14:	e54a                	sd	s2,136(sp)
    80005d16:	e94e                	sd	s3,144(sp)
    80005d18:	ed52                	sd	s4,152(sp)
    80005d1a:	f156                	sd	s5,160(sp)
    80005d1c:	f55a                	sd	s6,168(sp)
    80005d1e:	f95e                	sd	s7,176(sp)
    80005d20:	fd62                	sd	s8,184(sp)
    80005d22:	e1e6                	sd	s9,192(sp)
    80005d24:	e5ea                	sd	s10,200(sp)
    80005d26:	e9ee                	sd	s11,208(sp)
    80005d28:	edf2                	sd	t3,216(sp)
    80005d2a:	f1f6                	sd	t4,224(sp)
    80005d2c:	f5fa                	sd	t5,232(sp)
    80005d2e:	f9fe                	sd	t6,240(sp)
    80005d30:	cc3fc0ef          	jal	ra,800029f2 <kerneltrap>
    80005d34:	6082                	ld	ra,0(sp)
    80005d36:	6122                	ld	sp,8(sp)
    80005d38:	61c2                	ld	gp,16(sp)
    80005d3a:	7282                	ld	t0,32(sp)
    80005d3c:	7322                	ld	t1,40(sp)
    80005d3e:	73c2                	ld	t2,48(sp)
    80005d40:	7462                	ld	s0,56(sp)
    80005d42:	6486                	ld	s1,64(sp)
    80005d44:	6526                	ld	a0,72(sp)
    80005d46:	65c6                	ld	a1,80(sp)
    80005d48:	6666                	ld	a2,88(sp)
    80005d4a:	7686                	ld	a3,96(sp)
    80005d4c:	7726                	ld	a4,104(sp)
    80005d4e:	77c6                	ld	a5,112(sp)
    80005d50:	7866                	ld	a6,120(sp)
    80005d52:	688a                	ld	a7,128(sp)
    80005d54:	692a                	ld	s2,136(sp)
    80005d56:	69ca                	ld	s3,144(sp)
    80005d58:	6a6a                	ld	s4,152(sp)
    80005d5a:	7a8a                	ld	s5,160(sp)
    80005d5c:	7b2a                	ld	s6,168(sp)
    80005d5e:	7bca                	ld	s7,176(sp)
    80005d60:	7c6a                	ld	s8,184(sp)
    80005d62:	6c8e                	ld	s9,192(sp)
    80005d64:	6d2e                	ld	s10,200(sp)
    80005d66:	6dce                	ld	s11,208(sp)
    80005d68:	6e6e                	ld	t3,216(sp)
    80005d6a:	7e8e                	ld	t4,224(sp)
    80005d6c:	7f2e                	ld	t5,232(sp)
    80005d6e:	7fce                	ld	t6,240(sp)
    80005d70:	6111                	addi	sp,sp,256
    80005d72:	10200073          	sret
    80005d76:	00000013          	nop
    80005d7a:	00000013          	nop
    80005d7e:	0001                	nop

0000000080005d80 <timervec>:
    80005d80:	34051573          	csrrw	a0,mscratch,a0
    80005d84:	e10c                	sd	a1,0(a0)
    80005d86:	e510                	sd	a2,8(a0)
    80005d88:	e914                	sd	a3,16(a0)
    80005d8a:	6d0c                	ld	a1,24(a0)
    80005d8c:	7110                	ld	a2,32(a0)
    80005d8e:	6194                	ld	a3,0(a1)
    80005d90:	96b2                	add	a3,a3,a2
    80005d92:	e194                	sd	a3,0(a1)
    80005d94:	4589                	li	a1,2
    80005d96:	14459073          	csrw	sip,a1
    80005d9a:	6914                	ld	a3,16(a0)
    80005d9c:	6510                	ld	a2,8(a0)
    80005d9e:	610c                	ld	a1,0(a0)
    80005da0:	34051573          	csrrw	a0,mscratch,a0
    80005da4:	30200073          	mret
	...

0000000080005daa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005daa:	1141                	addi	sp,sp,-16
    80005dac:	e422                	sd	s0,8(sp)
    80005dae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005db0:	0c0007b7          	lui	a5,0xc000
    80005db4:	4705                	li	a4,1
    80005db6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005db8:	c3d8                	sw	a4,4(a5)
}
    80005dba:	6422                	ld	s0,8(sp)
    80005dbc:	0141                	addi	sp,sp,16
    80005dbe:	8082                	ret

0000000080005dc0 <plicinithart>:

void
plicinithart(void)
{
    80005dc0:	1141                	addi	sp,sp,-16
    80005dc2:	e406                	sd	ra,8(sp)
    80005dc4:	e022                	sd	s0,0(sp)
    80005dc6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	b9e080e7          	jalr	-1122(ra) # 80001966 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005dd0:	0085171b          	slliw	a4,a0,0x8
    80005dd4:	0c0027b7          	lui	a5,0xc002
    80005dd8:	97ba                	add	a5,a5,a4
    80005dda:	40200713          	li	a4,1026
    80005dde:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005de2:	00d5151b          	slliw	a0,a0,0xd
    80005de6:	0c2017b7          	lui	a5,0xc201
    80005dea:	953e                	add	a0,a0,a5
    80005dec:	00052023          	sw	zero,0(a0)
}
    80005df0:	60a2                	ld	ra,8(sp)
    80005df2:	6402                	ld	s0,0(sp)
    80005df4:	0141                	addi	sp,sp,16
    80005df6:	8082                	ret

0000000080005df8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005df8:	1141                	addi	sp,sp,-16
    80005dfa:	e406                	sd	ra,8(sp)
    80005dfc:	e022                	sd	s0,0(sp)
    80005dfe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e00:	ffffc097          	auipc	ra,0xffffc
    80005e04:	b66080e7          	jalr	-1178(ra) # 80001966 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e08:	00d5179b          	slliw	a5,a0,0xd
    80005e0c:	0c201537          	lui	a0,0xc201
    80005e10:	953e                	add	a0,a0,a5
  return irq;
}
    80005e12:	4148                	lw	a0,4(a0)
    80005e14:	60a2                	ld	ra,8(sp)
    80005e16:	6402                	ld	s0,0(sp)
    80005e18:	0141                	addi	sp,sp,16
    80005e1a:	8082                	ret

0000000080005e1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e1c:	1101                	addi	sp,sp,-32
    80005e1e:	ec06                	sd	ra,24(sp)
    80005e20:	e822                	sd	s0,16(sp)
    80005e22:	e426                	sd	s1,8(sp)
    80005e24:	1000                	addi	s0,sp,32
    80005e26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b3e080e7          	jalr	-1218(ra) # 80001966 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e30:	00d5151b          	slliw	a0,a0,0xd
    80005e34:	0c2017b7          	lui	a5,0xc201
    80005e38:	97aa                	add	a5,a5,a0
    80005e3a:	c3c4                	sw	s1,4(a5)
}
    80005e3c:	60e2                	ld	ra,24(sp)
    80005e3e:	6442                	ld	s0,16(sp)
    80005e40:	64a2                	ld	s1,8(sp)
    80005e42:	6105                	addi	sp,sp,32
    80005e44:	8082                	ret

0000000080005e46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e46:	1141                	addi	sp,sp,-16
    80005e48:	e406                	sd	ra,8(sp)
    80005e4a:	e022                	sd	s0,0(sp)
    80005e4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e4e:	479d                	li	a5,7
    80005e50:	06a7c963          	blt	a5,a0,80005ec2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005e54:	0001d797          	auipc	a5,0x1d
    80005e58:	1ac78793          	addi	a5,a5,428 # 80023000 <disk>
    80005e5c:	00a78733          	add	a4,a5,a0
    80005e60:	6789                	lui	a5,0x2
    80005e62:	97ba                	add	a5,a5,a4
    80005e64:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e68:	e7ad                	bnez	a5,80005ed2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e6a:	00451793          	slli	a5,a0,0x4
    80005e6e:	0001f717          	auipc	a4,0x1f
    80005e72:	19270713          	addi	a4,a4,402 # 80025000 <disk+0x2000>
    80005e76:	6314                	ld	a3,0(a4)
    80005e78:	96be                	add	a3,a3,a5
    80005e7a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005e7e:	6314                	ld	a3,0(a4)
    80005e80:	96be                	add	a3,a3,a5
    80005e82:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005e86:	6314                	ld	a3,0(a4)
    80005e88:	96be                	add	a3,a3,a5
    80005e8a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005e8e:	6318                	ld	a4,0(a4)
    80005e90:	97ba                	add	a5,a5,a4
    80005e92:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e96:	0001d797          	auipc	a5,0x1d
    80005e9a:	16a78793          	addi	a5,a5,362 # 80023000 <disk>
    80005e9e:	97aa                	add	a5,a5,a0
    80005ea0:	6509                	lui	a0,0x2
    80005ea2:	953e                	add	a0,a0,a5
    80005ea4:	4785                	li	a5,1
    80005ea6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005eaa:	0001f517          	auipc	a0,0x1f
    80005eae:	16e50513          	addi	a0,a0,366 # 80025018 <disk+0x2018>
    80005eb2:	ffffc097          	auipc	ra,0xffffc
    80005eb6:	386080e7          	jalr	902(ra) # 80002238 <wakeup>
}
    80005eba:	60a2                	ld	ra,8(sp)
    80005ebc:	6402                	ld	s0,0(sp)
    80005ebe:	0141                	addi	sp,sp,16
    80005ec0:	8082                	ret
    panic("free_desc 1");
    80005ec2:	00003517          	auipc	a0,0x3
    80005ec6:	ace50513          	addi	a0,a0,-1330 # 80008990 <syscalls_str+0x328>
    80005eca:	ffffa097          	auipc	ra,0xffffa
    80005ece:	660080e7          	jalr	1632(ra) # 8000052a <panic>
    panic("free_desc 2");
    80005ed2:	00003517          	auipc	a0,0x3
    80005ed6:	ace50513          	addi	a0,a0,-1330 # 800089a0 <syscalls_str+0x338>
    80005eda:	ffffa097          	auipc	ra,0xffffa
    80005ede:	650080e7          	jalr	1616(ra) # 8000052a <panic>

0000000080005ee2 <virtio_disk_init>:
{
    80005ee2:	1101                	addi	sp,sp,-32
    80005ee4:	ec06                	sd	ra,24(sp)
    80005ee6:	e822                	sd	s0,16(sp)
    80005ee8:	e426                	sd	s1,8(sp)
    80005eea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005eec:	00003597          	auipc	a1,0x3
    80005ef0:	ac458593          	addi	a1,a1,-1340 # 800089b0 <syscalls_str+0x348>
    80005ef4:	0001f517          	auipc	a0,0x1f
    80005ef8:	23450513          	addi	a0,a0,564 # 80025128 <disk+0x2128>
    80005efc:	ffffb097          	auipc	ra,0xffffb
    80005f00:	c36080e7          	jalr	-970(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f04:	100017b7          	lui	a5,0x10001
    80005f08:	4398                	lw	a4,0(a5)
    80005f0a:	2701                	sext.w	a4,a4
    80005f0c:	747277b7          	lui	a5,0x74727
    80005f10:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f14:	0ef71163          	bne	a4,a5,80005ff6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f18:	100017b7          	lui	a5,0x10001
    80005f1c:	43dc                	lw	a5,4(a5)
    80005f1e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f20:	4705                	li	a4,1
    80005f22:	0ce79a63          	bne	a5,a4,80005ff6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f26:	100017b7          	lui	a5,0x10001
    80005f2a:	479c                	lw	a5,8(a5)
    80005f2c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f2e:	4709                	li	a4,2
    80005f30:	0ce79363          	bne	a5,a4,80005ff6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f34:	100017b7          	lui	a5,0x10001
    80005f38:	47d8                	lw	a4,12(a5)
    80005f3a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f3c:	554d47b7          	lui	a5,0x554d4
    80005f40:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f44:	0af71963          	bne	a4,a5,80005ff6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f48:	100017b7          	lui	a5,0x10001
    80005f4c:	4705                	li	a4,1
    80005f4e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f50:	470d                	li	a4,3
    80005f52:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f54:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f56:	c7ffe737          	lui	a4,0xc7ffe
    80005f5a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f5e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f60:	2701                	sext.w	a4,a4
    80005f62:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f64:	472d                	li	a4,11
    80005f66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f68:	473d                	li	a4,15
    80005f6a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f6c:	6705                	lui	a4,0x1
    80005f6e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f70:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f74:	5bdc                	lw	a5,52(a5)
    80005f76:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f78:	c7d9                	beqz	a5,80006006 <virtio_disk_init+0x124>
  if(max < NUM)
    80005f7a:	471d                	li	a4,7
    80005f7c:	08f77d63          	bgeu	a4,a5,80006016 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f80:	100014b7          	lui	s1,0x10001
    80005f84:	47a1                	li	a5,8
    80005f86:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f88:	6609                	lui	a2,0x2
    80005f8a:	4581                	li	a1,0
    80005f8c:	0001d517          	auipc	a0,0x1d
    80005f90:	07450513          	addi	a0,a0,116 # 80023000 <disk>
    80005f94:	ffffb097          	auipc	ra,0xffffb
    80005f98:	d2a080e7          	jalr	-726(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f9c:	0001d717          	auipc	a4,0x1d
    80005fa0:	06470713          	addi	a4,a4,100 # 80023000 <disk>
    80005fa4:	00c75793          	srli	a5,a4,0xc
    80005fa8:	2781                	sext.w	a5,a5
    80005faa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005fac:	0001f797          	auipc	a5,0x1f
    80005fb0:	05478793          	addi	a5,a5,84 # 80025000 <disk+0x2000>
    80005fb4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005fb6:	0001d717          	auipc	a4,0x1d
    80005fba:	0ca70713          	addi	a4,a4,202 # 80023080 <disk+0x80>
    80005fbe:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005fc0:	0001e717          	auipc	a4,0x1e
    80005fc4:	04070713          	addi	a4,a4,64 # 80024000 <disk+0x1000>
    80005fc8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fca:	4705                	li	a4,1
    80005fcc:	00e78c23          	sb	a4,24(a5)
    80005fd0:	00e78ca3          	sb	a4,25(a5)
    80005fd4:	00e78d23          	sb	a4,26(a5)
    80005fd8:	00e78da3          	sb	a4,27(a5)
    80005fdc:	00e78e23          	sb	a4,28(a5)
    80005fe0:	00e78ea3          	sb	a4,29(a5)
    80005fe4:	00e78f23          	sb	a4,30(a5)
    80005fe8:	00e78fa3          	sb	a4,31(a5)
}
    80005fec:	60e2                	ld	ra,24(sp)
    80005fee:	6442                	ld	s0,16(sp)
    80005ff0:	64a2                	ld	s1,8(sp)
    80005ff2:	6105                	addi	sp,sp,32
    80005ff4:	8082                	ret
    panic("could not find virtio disk");
    80005ff6:	00003517          	auipc	a0,0x3
    80005ffa:	9ca50513          	addi	a0,a0,-1590 # 800089c0 <syscalls_str+0x358>
    80005ffe:	ffffa097          	auipc	ra,0xffffa
    80006002:	52c080e7          	jalr	1324(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    80006006:	00003517          	auipc	a0,0x3
    8000600a:	9da50513          	addi	a0,a0,-1574 # 800089e0 <syscalls_str+0x378>
    8000600e:	ffffa097          	auipc	ra,0xffffa
    80006012:	51c080e7          	jalr	1308(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    80006016:	00003517          	auipc	a0,0x3
    8000601a:	9ea50513          	addi	a0,a0,-1558 # 80008a00 <syscalls_str+0x398>
    8000601e:	ffffa097          	auipc	ra,0xffffa
    80006022:	50c080e7          	jalr	1292(ra) # 8000052a <panic>

0000000080006026 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006026:	7119                	addi	sp,sp,-128
    80006028:	fc86                	sd	ra,120(sp)
    8000602a:	f8a2                	sd	s0,112(sp)
    8000602c:	f4a6                	sd	s1,104(sp)
    8000602e:	f0ca                	sd	s2,96(sp)
    80006030:	ecce                	sd	s3,88(sp)
    80006032:	e8d2                	sd	s4,80(sp)
    80006034:	e4d6                	sd	s5,72(sp)
    80006036:	e0da                	sd	s6,64(sp)
    80006038:	fc5e                	sd	s7,56(sp)
    8000603a:	f862                	sd	s8,48(sp)
    8000603c:	f466                	sd	s9,40(sp)
    8000603e:	f06a                	sd	s10,32(sp)
    80006040:	ec6e                	sd	s11,24(sp)
    80006042:	0100                	addi	s0,sp,128
    80006044:	8aaa                	mv	s5,a0
    80006046:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006048:	00c52c83          	lw	s9,12(a0)
    8000604c:	001c9c9b          	slliw	s9,s9,0x1
    80006050:	1c82                	slli	s9,s9,0x20
    80006052:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006056:	0001f517          	auipc	a0,0x1f
    8000605a:	0d250513          	addi	a0,a0,210 # 80025128 <disk+0x2128>
    8000605e:	ffffb097          	auipc	ra,0xffffb
    80006062:	b64080e7          	jalr	-1180(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006066:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006068:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000606a:	0001dc17          	auipc	s8,0x1d
    8000606e:	f96c0c13          	addi	s8,s8,-106 # 80023000 <disk>
    80006072:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006074:	4b0d                	li	s6,3
    80006076:	a0ad                	j	800060e0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006078:	00fc0733          	add	a4,s8,a5
    8000607c:	975e                	add	a4,a4,s7
    8000607e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006082:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006084:	0207c563          	bltz	a5,800060ae <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006088:	2905                	addiw	s2,s2,1
    8000608a:	0611                	addi	a2,a2,4
    8000608c:	19690d63          	beq	s2,s6,80006226 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006090:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006092:	0001f717          	auipc	a4,0x1f
    80006096:	f8670713          	addi	a4,a4,-122 # 80025018 <disk+0x2018>
    8000609a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000609c:	00074683          	lbu	a3,0(a4)
    800060a0:	fee1                	bnez	a3,80006078 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060a2:	2785                	addiw	a5,a5,1
    800060a4:	0705                	addi	a4,a4,1
    800060a6:	fe979be3          	bne	a5,s1,8000609c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060aa:	57fd                	li	a5,-1
    800060ac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ae:	01205d63          	blez	s2,800060c8 <virtio_disk_rw+0xa2>
    800060b2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060b4:	000a2503          	lw	a0,0(s4)
    800060b8:	00000097          	auipc	ra,0x0
    800060bc:	d8e080e7          	jalr	-626(ra) # 80005e46 <free_desc>
      for(int j = 0; j < i; j++)
    800060c0:	2d85                	addiw	s11,s11,1
    800060c2:	0a11                	addi	s4,s4,4
    800060c4:	ffb918e3          	bne	s2,s11,800060b4 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060c8:	0001f597          	auipc	a1,0x1f
    800060cc:	06058593          	addi	a1,a1,96 # 80025128 <disk+0x2128>
    800060d0:	0001f517          	auipc	a0,0x1f
    800060d4:	f4850513          	addi	a0,a0,-184 # 80025018 <disk+0x2018>
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	fd4080e7          	jalr	-44(ra) # 800020ac <sleep>
  for(int i = 0; i < 3; i++){
    800060e0:	f8040a13          	addi	s4,s0,-128
{
    800060e4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060e6:	894e                	mv	s2,s3
    800060e8:	b765                	j	80006090 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ea:	0001f697          	auipc	a3,0x1f
    800060ee:	f166b683          	ld	a3,-234(a3) # 80025000 <disk+0x2000>
    800060f2:	96ba                	add	a3,a3,a4
    800060f4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060f8:	0001d817          	auipc	a6,0x1d
    800060fc:	f0880813          	addi	a6,a6,-248 # 80023000 <disk>
    80006100:	0001f697          	auipc	a3,0x1f
    80006104:	f0068693          	addi	a3,a3,-256 # 80025000 <disk+0x2000>
    80006108:	6290                	ld	a2,0(a3)
    8000610a:	963a                	add	a2,a2,a4
    8000610c:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    80006110:	0015e593          	ori	a1,a1,1
    80006114:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    80006118:	f8842603          	lw	a2,-120(s0)
    8000611c:	628c                	ld	a1,0(a3)
    8000611e:	972e                	add	a4,a4,a1
    80006120:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006124:	20050593          	addi	a1,a0,512
    80006128:	0592                	slli	a1,a1,0x4
    8000612a:	95c2                	add	a1,a1,a6
    8000612c:	577d                	li	a4,-1
    8000612e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006132:	00461713          	slli	a4,a2,0x4
    80006136:	6290                	ld	a2,0(a3)
    80006138:	963a                	add	a2,a2,a4
    8000613a:	03078793          	addi	a5,a5,48
    8000613e:	97c2                	add	a5,a5,a6
    80006140:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006142:	629c                	ld	a5,0(a3)
    80006144:	97ba                	add	a5,a5,a4
    80006146:	4605                	li	a2,1
    80006148:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000614a:	629c                	ld	a5,0(a3)
    8000614c:	97ba                	add	a5,a5,a4
    8000614e:	4809                	li	a6,2
    80006150:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006154:	629c                	ld	a5,0(a3)
    80006156:	973e                	add	a4,a4,a5
    80006158:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000615c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006160:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006164:	6698                	ld	a4,8(a3)
    80006166:	00275783          	lhu	a5,2(a4)
    8000616a:	8b9d                	andi	a5,a5,7
    8000616c:	0786                	slli	a5,a5,0x1
    8000616e:	97ba                	add	a5,a5,a4
    80006170:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006174:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006178:	6698                	ld	a4,8(a3)
    8000617a:	00275783          	lhu	a5,2(a4)
    8000617e:	2785                	addiw	a5,a5,1
    80006180:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006184:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006188:	100017b7          	lui	a5,0x10001
    8000618c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006190:	004aa783          	lw	a5,4(s5)
    80006194:	02c79163          	bne	a5,a2,800061b6 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006198:	0001f917          	auipc	s2,0x1f
    8000619c:	f9090913          	addi	s2,s2,-112 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061a0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061a2:	85ca                	mv	a1,s2
    800061a4:	8556                	mv	a0,s5
    800061a6:	ffffc097          	auipc	ra,0xffffc
    800061aa:	f06080e7          	jalr	-250(ra) # 800020ac <sleep>
  while(b->disk == 1) {
    800061ae:	004aa783          	lw	a5,4(s5)
    800061b2:	fe9788e3          	beq	a5,s1,800061a2 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    800061b6:	f8042903          	lw	s2,-128(s0)
    800061ba:	20090793          	addi	a5,s2,512
    800061be:	00479713          	slli	a4,a5,0x4
    800061c2:	0001d797          	auipc	a5,0x1d
    800061c6:	e3e78793          	addi	a5,a5,-450 # 80023000 <disk>
    800061ca:	97ba                	add	a5,a5,a4
    800061cc:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061d0:	0001f997          	auipc	s3,0x1f
    800061d4:	e3098993          	addi	s3,s3,-464 # 80025000 <disk+0x2000>
    800061d8:	00491713          	slli	a4,s2,0x4
    800061dc:	0009b783          	ld	a5,0(s3)
    800061e0:	97ba                	add	a5,a5,a4
    800061e2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061e6:	854a                	mv	a0,s2
    800061e8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061ec:	00000097          	auipc	ra,0x0
    800061f0:	c5a080e7          	jalr	-934(ra) # 80005e46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061f4:	8885                	andi	s1,s1,1
    800061f6:	f0ed                	bnez	s1,800061d8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061f8:	0001f517          	auipc	a0,0x1f
    800061fc:	f3050513          	addi	a0,a0,-208 # 80025128 <disk+0x2128>
    80006200:	ffffb097          	auipc	ra,0xffffb
    80006204:	a76080e7          	jalr	-1418(ra) # 80000c76 <release>
}
    80006208:	70e6                	ld	ra,120(sp)
    8000620a:	7446                	ld	s0,112(sp)
    8000620c:	74a6                	ld	s1,104(sp)
    8000620e:	7906                	ld	s2,96(sp)
    80006210:	69e6                	ld	s3,88(sp)
    80006212:	6a46                	ld	s4,80(sp)
    80006214:	6aa6                	ld	s5,72(sp)
    80006216:	6b06                	ld	s6,64(sp)
    80006218:	7be2                	ld	s7,56(sp)
    8000621a:	7c42                	ld	s8,48(sp)
    8000621c:	7ca2                	ld	s9,40(sp)
    8000621e:	7d02                	ld	s10,32(sp)
    80006220:	6de2                	ld	s11,24(sp)
    80006222:	6109                	addi	sp,sp,128
    80006224:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006226:	f8042503          	lw	a0,-128(s0)
    8000622a:	20050793          	addi	a5,a0,512
    8000622e:	0792                	slli	a5,a5,0x4
  if(write)
    80006230:	0001d817          	auipc	a6,0x1d
    80006234:	dd080813          	addi	a6,a6,-560 # 80023000 <disk>
    80006238:	00f80733          	add	a4,a6,a5
    8000623c:	01a036b3          	snez	a3,s10
    80006240:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006244:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006248:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000624c:	7679                	lui	a2,0xffffe
    8000624e:	963e                	add	a2,a2,a5
    80006250:	0001f697          	auipc	a3,0x1f
    80006254:	db068693          	addi	a3,a3,-592 # 80025000 <disk+0x2000>
    80006258:	6298                	ld	a4,0(a3)
    8000625a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000625c:	0a878593          	addi	a1,a5,168
    80006260:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006262:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006264:	6298                	ld	a4,0(a3)
    80006266:	9732                	add	a4,a4,a2
    80006268:	45c1                	li	a1,16
    8000626a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000626c:	6298                	ld	a4,0(a3)
    8000626e:	9732                	add	a4,a4,a2
    80006270:	4585                	li	a1,1
    80006272:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006276:	f8442703          	lw	a4,-124(s0)
    8000627a:	628c                	ld	a1,0(a3)
    8000627c:	962e                	add	a2,a2,a1
    8000627e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006282:	0712                	slli	a4,a4,0x4
    80006284:	6290                	ld	a2,0(a3)
    80006286:	963a                	add	a2,a2,a4
    80006288:	058a8593          	addi	a1,s5,88
    8000628c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000628e:	6294                	ld	a3,0(a3)
    80006290:	96ba                	add	a3,a3,a4
    80006292:	40000613          	li	a2,1024
    80006296:	c690                	sw	a2,8(a3)
  if(write)
    80006298:	e40d19e3          	bnez	s10,800060ea <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000629c:	0001f697          	auipc	a3,0x1f
    800062a0:	d646b683          	ld	a3,-668(a3) # 80025000 <disk+0x2000>
    800062a4:	96ba                	add	a3,a3,a4
    800062a6:	4609                	li	a2,2
    800062a8:	00c69623          	sh	a2,12(a3)
    800062ac:	b5b1                	j	800060f8 <virtio_disk_rw+0xd2>

00000000800062ae <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062ae:	1101                	addi	sp,sp,-32
    800062b0:	ec06                	sd	ra,24(sp)
    800062b2:	e822                	sd	s0,16(sp)
    800062b4:	e426                	sd	s1,8(sp)
    800062b6:	e04a                	sd	s2,0(sp)
    800062b8:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062ba:	0001f517          	auipc	a0,0x1f
    800062be:	e6e50513          	addi	a0,a0,-402 # 80025128 <disk+0x2128>
    800062c2:	ffffb097          	auipc	ra,0xffffb
    800062c6:	900080e7          	jalr	-1792(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062ca:	10001737          	lui	a4,0x10001
    800062ce:	533c                	lw	a5,96(a4)
    800062d0:	8b8d                	andi	a5,a5,3
    800062d2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062d4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062d8:	0001f797          	auipc	a5,0x1f
    800062dc:	d2878793          	addi	a5,a5,-728 # 80025000 <disk+0x2000>
    800062e0:	6b94                	ld	a3,16(a5)
    800062e2:	0207d703          	lhu	a4,32(a5)
    800062e6:	0026d783          	lhu	a5,2(a3)
    800062ea:	06f70163          	beq	a4,a5,8000634c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ee:	0001d917          	auipc	s2,0x1d
    800062f2:	d1290913          	addi	s2,s2,-750 # 80023000 <disk>
    800062f6:	0001f497          	auipc	s1,0x1f
    800062fa:	d0a48493          	addi	s1,s1,-758 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062fe:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006302:	6898                	ld	a4,16(s1)
    80006304:	0204d783          	lhu	a5,32(s1)
    80006308:	8b9d                	andi	a5,a5,7
    8000630a:	078e                	slli	a5,a5,0x3
    8000630c:	97ba                	add	a5,a5,a4
    8000630e:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006310:	20078713          	addi	a4,a5,512
    80006314:	0712                	slli	a4,a4,0x4
    80006316:	974a                	add	a4,a4,s2
    80006318:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000631c:	e731                	bnez	a4,80006368 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000631e:	20078793          	addi	a5,a5,512
    80006322:	0792                	slli	a5,a5,0x4
    80006324:	97ca                	add	a5,a5,s2
    80006326:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006328:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000632c:	ffffc097          	auipc	ra,0xffffc
    80006330:	f0c080e7          	jalr	-244(ra) # 80002238 <wakeup>

    disk.used_idx += 1;
    80006334:	0204d783          	lhu	a5,32(s1)
    80006338:	2785                	addiw	a5,a5,1
    8000633a:	17c2                	slli	a5,a5,0x30
    8000633c:	93c1                	srli	a5,a5,0x30
    8000633e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006342:	6898                	ld	a4,16(s1)
    80006344:	00275703          	lhu	a4,2(a4)
    80006348:	faf71be3          	bne	a4,a5,800062fe <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000634c:	0001f517          	auipc	a0,0x1f
    80006350:	ddc50513          	addi	a0,a0,-548 # 80025128 <disk+0x2128>
    80006354:	ffffb097          	auipc	ra,0xffffb
    80006358:	922080e7          	jalr	-1758(ra) # 80000c76 <release>
}
    8000635c:	60e2                	ld	ra,24(sp)
    8000635e:	6442                	ld	s0,16(sp)
    80006360:	64a2                	ld	s1,8(sp)
    80006362:	6902                	ld	s2,0(sp)
    80006364:	6105                	addi	sp,sp,32
    80006366:	8082                	ret
      panic("virtio_disk_intr status");
    80006368:	00002517          	auipc	a0,0x2
    8000636c:	6b850513          	addi	a0,a0,1720 # 80008a20 <syscalls_str+0x3b8>
    80006370:	ffffa097          	auipc	ra,0xffffa
    80006374:	1ba080e7          	jalr	442(ra) # 8000052a <panic>
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
