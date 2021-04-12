
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
    80000068:	efc78793          	addi	a5,a5,-260 # 80005f60 <timervec>
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
    80000122:	5d8080e7          	jalr	1496(ra) # 800026f6 <either_copyin>
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
    800001c6:	f00080e7          	jalr	-256(ra) # 800020c2 <sleep>
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
    80000202:	4a2080e7          	jalr	1186(ra) # 800026a0 <either_copyout>
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
    800002e2:	46e080e7          	jalr	1134(ra) # 8000274c <procdump>
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
    80000436:	e1c080e7          	jalr	-484(ra) # 8000224e <wakeup>
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
    80000882:	9d0080e7          	jalr	-1584(ra) # 8000224e <wakeup>
    
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
    8000090e:	7b8080e7          	jalr	1976(ra) # 800020c2 <sleep>
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
    80000eb6:	9dc080e7          	jalr	-1572(ra) # 8000288e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000eba:	00005097          	auipc	ra,0x5
    80000ebe:	0e6080e7          	jalr	230(ra) # 80005fa0 <plicinithart>
  }

  scheduler();        
    80000ec2:	00001097          	auipc	ra,0x1
    80000ec6:	028080e7          	jalr	40(ra) # 80001eea <scheduler>
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
    80000f2e:	93c080e7          	jalr	-1732(ra) # 80002866 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f32:	00002097          	auipc	ra,0x2
    80000f36:	95c080e7          	jalr	-1700(ra) # 8000288e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f3a:	00005097          	auipc	ra,0x5
    80000f3e:	050080e7          	jalr	80(ra) # 80005f8a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	05e080e7          	jalr	94(ra) # 80005fa0 <plicinithart>
    binit();         // buffer cache
    80000f4a:	00002097          	auipc	ra,0x2
    80000f4e:	230080e7          	jalr	560(ra) # 8000317a <binit>
    iinit();         // inode cache
    80000f52:	00003097          	auipc	ra,0x3
    80000f56:	8c2080e7          	jalr	-1854(ra) # 80003814 <iinit>
    fileinit();      // file table
    80000f5a:	00004097          	auipc	ra,0x4
    80000f5e:	870080e7          	jalr	-1936(ra) # 800047ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	160080e7          	jalr	352(ra) # 800060c2 <virtio_disk_init>
    userinit();      // first user process
    80000f6a:	00001097          	auipc	ra,0x1
    80000f6e:	d42080e7          	jalr	-702(ra) # 80001cac <userinit>
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
    80001948:	ecbc                	sd	a5,88(s1)
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
    800019e6:	12e7a783          	lw	a5,302(a5) # 80008b10 <first.1>
    800019ea:	eb89                	bnez	a5,800019fc <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    800019ec:	00001097          	auipc	ra,0x1
    800019f0:	eba080e7          	jalr	-326(ra) # 800028a6 <usertrapret>
}
    800019f4:	60a2                	ld	ra,8(sp)
    800019f6:	6402                	ld	s0,0(sp)
    800019f8:	0141                	addi	sp,sp,16
    800019fa:	8082                	ret
    first = 0;
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	1007aa23          	sw	zero,276(a5) # 80008b10 <first.1>
    fsinit(ROOTDEV);
    80001a04:	4505                	li	a0,1
    80001a06:	00002097          	auipc	ra,0x2
    80001a0a:	d8e080e7          	jalr	-626(ra) # 80003794 <fsinit>
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
    80001a32:	0e678793          	addi	a5,a5,230 # 80008b14 <nextpid>
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
    80001a92:	07093683          	ld	a3,112(s2)
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
    80001b50:	7928                	ld	a0,112(a0)
    80001b52:	c509                	beqz	a0,80001b5c <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b54:	fffff097          	auipc	ra,0xfffff
    80001b58:	e82080e7          	jalr	-382(ra) # 800009d6 <kfree>
  p->trapframe = 0;
    80001b5c:	0604b823          	sd	zero,112(s1)
  if (p->pagetable)
    80001b60:	74a8                	ld	a0,104(s1)
    80001b62:	c511                	beqz	a0,80001b6e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b64:	70ac                	ld	a1,96(s1)
    80001b66:	00000097          	auipc	ra,0x0
    80001b6a:	f8c080e7          	jalr	-116(ra) # 80001af2 <proc_freepagetable>
  p->pagetable = 0;
    80001b6e:	0604b423          	sd	zero,104(s1)
  p->sz = 0;
    80001b72:	0604b023          	sd	zero,96(s1)
  p->pid = 0;
    80001b76:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b7a:	0404b823          	sd	zero,80(s1)
  p->name[0] = 0;
    80001b7e:	16048823          	sb	zero,368(s1)
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
    80001bda:	a851                	j	80001c6e <allocproc+0xd2>
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
    80001bf4:	f8a8                	sd	a0,112(s1)
    80001bf6:	c159                	beqz	a0,80001c7c <allocproc+0xe0>
  p->pagetable = proc_pagetable(p);
    80001bf8:	8526                	mv	a0,s1
    80001bfa:	00000097          	auipc	ra,0x0
    80001bfe:	e5c080e7          	jalr	-420(ra) # 80001a56 <proc_pagetable>
    80001c02:	892a                	mv	s2,a0
    80001c04:	f4a8                	sd	a0,104(s1)
  if (p->pagetable == 0)
    80001c06:	c559                	beqz	a0,80001c94 <allocproc+0xf8>
  memset(&p->context, 0, sizeof(p->context));
    80001c08:	07000613          	li	a2,112
    80001c0c:	4581                	li	a1,0
    80001c0e:	07848513          	addi	a0,s1,120
    80001c12:	fffff097          	auipc	ra,0xfffff
    80001c16:	0ac080e7          	jalr	172(ra) # 80000cbe <memset>
  p->context.ra = (uint64)forkret;
    80001c1a:	00000797          	auipc	a5,0x0
    80001c1e:	db078793          	addi	a5,a5,-592 # 800019ca <forkret>
    80001c22:	fcbc                	sd	a5,120(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c24:	6cbc                	ld	a5,88(s1)
    80001c26:	6705                	lui	a4,0x1
    80001c28:	97ba                	add	a5,a5,a4
    80001c2a:	e0dc                	sd	a5,128(s1)
  p->traceMask = 0; //initially no sys calls are traced
    80001c2c:	0204aa23          	sw	zero,52(s1)
  p->retime = 0;
    80001c30:	0404a223          	sw	zero,68(s1)
  p->runtime = 0;
    80001c34:	0404a423          	sw	zero,72(s1)
  p->stime = 0;
    80001c38:	0404a023          	sw	zero,64(s1)
  p->ttime = -1;
    80001c3c:	57fd                	li	a5,-1
    80001c3e:	dcdc                	sw	a5,60(s1)
  p->average_bursttime = QUANTUM;
    80001c40:	4785                	li	a5,1
    80001c42:	c4fc                	sw	a5,76(s1)
  acquire(&tickslock);
    80001c44:	00016517          	auipc	a0,0x16
    80001c48:	a8c50513          	addi	a0,a0,-1396 # 800176d0 <tickslock>
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	f76080e7          	jalr	-138(ra) # 80000bc2 <acquire>
  p->ctime = ticks;
    80001c54:	00007797          	auipc	a5,0x7
    80001c58:	3dc7a783          	lw	a5,988(a5) # 80009030 <ticks>
    80001c5c:	dc9c                	sw	a5,56(s1)
  release(&tickslock);
    80001c5e:	00016517          	auipc	a0,0x16
    80001c62:	a7250513          	addi	a0,a0,-1422 # 800176d0 <tickslock>
    80001c66:	fffff097          	auipc	ra,0xfffff
    80001c6a:	010080e7          	jalr	16(ra) # 80000c76 <release>
}
    80001c6e:	8526                	mv	a0,s1
    80001c70:	60e2                	ld	ra,24(sp)
    80001c72:	6442                	ld	s0,16(sp)
    80001c74:	64a2                	ld	s1,8(sp)
    80001c76:	6902                	ld	s2,0(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret
    freeproc(p);
    80001c7c:	8526                	mv	a0,s1
    80001c7e:	00000097          	auipc	ra,0x0
    80001c82:	ec6080e7          	jalr	-314(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	fee080e7          	jalr	-18(ra) # 80000c76 <release>
    return 0;
    80001c90:	84ca                	mv	s1,s2
    80001c92:	bff1                	j	80001c6e <allocproc+0xd2>
    freeproc(p);
    80001c94:	8526                	mv	a0,s1
    80001c96:	00000097          	auipc	ra,0x0
    80001c9a:	eae080e7          	jalr	-338(ra) # 80001b44 <freeproc>
    release(&p->lock);
    80001c9e:	8526                	mv	a0,s1
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	fd6080e7          	jalr	-42(ra) # 80000c76 <release>
    return 0;
    80001ca8:	84ca                	mv	s1,s2
    80001caa:	b7d1                	j	80001c6e <allocproc+0xd2>

0000000080001cac <userinit>:
{
    80001cac:	1101                	addi	sp,sp,-32
    80001cae:	ec06                	sd	ra,24(sp)
    80001cb0:	e822                	sd	s0,16(sp)
    80001cb2:	e426                	sd	s1,8(sp)
    80001cb4:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	ee6080e7          	jalr	-282(ra) # 80001b9c <allocproc>
    80001cbe:	84aa                	mv	s1,a0
  initproc = p;
    80001cc0:	00007797          	auipc	a5,0x7
    80001cc4:	36a7b423          	sd	a0,872(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cc8:	03400613          	li	a2,52
    80001ccc:	00007597          	auipc	a1,0x7
    80001cd0:	e5458593          	addi	a1,a1,-428 # 80008b20 <initcode>
    80001cd4:	7528                	ld	a0,104(a0)
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	65e080e7          	jalr	1630(ra) # 80001334 <uvminit>
  p->sz = PGSIZE;
    80001cde:	6785                	lui	a5,0x1
    80001ce0:	f0bc                	sd	a5,96(s1)
  p->trapframe->epc = 0;     // user program counter
    80001ce2:	78b8                	ld	a4,112(s1)
    80001ce4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001ce8:	78b8                	ld	a4,112(s1)
    80001cea:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cec:	4641                	li	a2,16
    80001cee:	00006597          	auipc	a1,0x6
    80001cf2:	4fa58593          	addi	a1,a1,1274 # 800081e8 <digits+0x1a8>
    80001cf6:	17048513          	addi	a0,s1,368
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	116080e7          	jalr	278(ra) # 80000e10 <safestrcpy>
  p->cwd = namei("/");
    80001d02:	00006517          	auipc	a0,0x6
    80001d06:	4f650513          	addi	a0,a0,1270 # 800081f8 <digits+0x1b8>
    80001d0a:	00002097          	auipc	ra,0x2
    80001d0e:	4b8080e7          	jalr	1208(ra) # 800041c2 <namei>
    80001d12:	16a4b423          	sd	a0,360(s1)
  p->state = RUNNABLE;
    80001d16:	478d                	li	a5,3
    80001d18:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	f5a080e7          	jalr	-166(ra) # 80000c76 <release>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <growproc>:
{
    80001d2e:	1101                	addi	sp,sp,-32
    80001d30:	ec06                	sd	ra,24(sp)
    80001d32:	e822                	sd	s0,16(sp)
    80001d34:	e426                	sd	s1,8(sp)
    80001d36:	e04a                	sd	s2,0(sp)
    80001d38:	1000                	addi	s0,sp,32
    80001d3a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	c56080e7          	jalr	-938(ra) # 80001992 <myproc>
    80001d44:	892a                	mv	s2,a0
  sz = p->sz;
    80001d46:	712c                	ld	a1,96(a0)
    80001d48:	0005861b          	sext.w	a2,a1
  if (n > 0)
    80001d4c:	00904f63          	bgtz	s1,80001d6a <growproc+0x3c>
  else if (n < 0)
    80001d50:	0204cc63          	bltz	s1,80001d88 <growproc+0x5a>
  p->sz = sz;
    80001d54:	1602                	slli	a2,a2,0x20
    80001d56:	9201                	srli	a2,a2,0x20
    80001d58:	06c93023          	sd	a2,96(s2)
  return 0;
    80001d5c:	4501                	li	a0,0
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6902                	ld	s2,0(sp)
    80001d66:	6105                	addi	sp,sp,32
    80001d68:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0)
    80001d6a:	9e25                	addw	a2,a2,s1
    80001d6c:	1602                	slli	a2,a2,0x20
    80001d6e:	9201                	srli	a2,a2,0x20
    80001d70:	1582                	slli	a1,a1,0x20
    80001d72:	9181                	srli	a1,a1,0x20
    80001d74:	7528                	ld	a0,104(a0)
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	678080e7          	jalr	1656(ra) # 800013ee <uvmalloc>
    80001d7e:	0005061b          	sext.w	a2,a0
    80001d82:	fa69                	bnez	a2,80001d54 <growproc+0x26>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	bfe1                	j	80001d5e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d88:	9e25                	addw	a2,a2,s1
    80001d8a:	1602                	slli	a2,a2,0x20
    80001d8c:	9201                	srli	a2,a2,0x20
    80001d8e:	1582                	slli	a1,a1,0x20
    80001d90:	9181                	srli	a1,a1,0x20
    80001d92:	7528                	ld	a0,104(a0)
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	612080e7          	jalr	1554(ra) # 800013a6 <uvmdealloc>
    80001d9c:	0005061b          	sext.w	a2,a0
    80001da0:	bf55                	j	80001d54 <growproc+0x26>

0000000080001da2 <fork>:
{
    80001da2:	7139                	addi	sp,sp,-64
    80001da4:	fc06                	sd	ra,56(sp)
    80001da6:	f822                	sd	s0,48(sp)
    80001da8:	f426                	sd	s1,40(sp)
    80001daa:	f04a                	sd	s2,32(sp)
    80001dac:	ec4e                	sd	s3,24(sp)
    80001dae:	e852                	sd	s4,16(sp)
    80001db0:	e456                	sd	s5,8(sp)
    80001db2:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001db4:	00000097          	auipc	ra,0x0
    80001db8:	bde080e7          	jalr	-1058(ra) # 80001992 <myproc>
    80001dbc:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	dde080e7          	jalr	-546(ra) # 80001b9c <allocproc>
    80001dc6:	12050063          	beqz	a0,80001ee6 <fork+0x144>
    80001dca:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dcc:	060ab603          	ld	a2,96(s5)
    80001dd0:	752c                	ld	a1,104(a0)
    80001dd2:	068ab503          	ld	a0,104(s5)
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	764080e7          	jalr	1892(ra) # 8000153a <uvmcopy>
    80001dde:	04054863          	bltz	a0,80001e2e <fork+0x8c>
  np->sz = p->sz;
    80001de2:	060ab783          	ld	a5,96(s5)
    80001de6:	06f9b023          	sd	a5,96(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dea:	070ab683          	ld	a3,112(s5)
    80001dee:	87b6                	mv	a5,a3
    80001df0:	0709b703          	ld	a4,112(s3)
    80001df4:	12068693          	addi	a3,a3,288
    80001df8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dfc:	6788                	ld	a0,8(a5)
    80001dfe:	6b8c                	ld	a1,16(a5)
    80001e00:	6f90                	ld	a2,24(a5)
    80001e02:	01073023          	sd	a6,0(a4)
    80001e06:	e708                	sd	a0,8(a4)
    80001e08:	eb0c                	sd	a1,16(a4)
    80001e0a:	ef10                	sd	a2,24(a4)
    80001e0c:	02078793          	addi	a5,a5,32
    80001e10:	02070713          	addi	a4,a4,32
    80001e14:	fed792e3          	bne	a5,a3,80001df8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e18:	0709b783          	ld	a5,112(s3)
    80001e1c:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e20:	0e8a8493          	addi	s1,s5,232
    80001e24:	0e898913          	addi	s2,s3,232
    80001e28:	168a8a13          	addi	s4,s5,360
    80001e2c:	a00d                	j	80001e4e <fork+0xac>
    freeproc(np);
    80001e2e:	854e                	mv	a0,s3
    80001e30:	00000097          	auipc	ra,0x0
    80001e34:	d14080e7          	jalr	-748(ra) # 80001b44 <freeproc>
    release(&np->lock);
    80001e38:	854e                	mv	a0,s3
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	e3c080e7          	jalr	-452(ra) # 80000c76 <release>
    return -1;
    80001e42:	597d                	li	s2,-1
    80001e44:	a079                	j	80001ed2 <fork+0x130>
  for (i = 0; i < NOFILE; i++)
    80001e46:	04a1                	addi	s1,s1,8
    80001e48:	0921                	addi	s2,s2,8
    80001e4a:	01448b63          	beq	s1,s4,80001e60 <fork+0xbe>
    if (p->ofile[i])
    80001e4e:	6088                	ld	a0,0(s1)
    80001e50:	d97d                	beqz	a0,80001e46 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e52:	00003097          	auipc	ra,0x3
    80001e56:	a0a080e7          	jalr	-1526(ra) # 8000485c <filedup>
    80001e5a:	00a93023          	sd	a0,0(s2)
    80001e5e:	b7e5                	j	80001e46 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e60:	168ab503          	ld	a0,360(s5)
    80001e64:	00002097          	auipc	ra,0x2
    80001e68:	b6a080e7          	jalr	-1174(ra) # 800039ce <idup>
    80001e6c:	16a9b423          	sd	a0,360(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e70:	4641                	li	a2,16
    80001e72:	170a8593          	addi	a1,s5,368
    80001e76:	17098513          	addi	a0,s3,368
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	f96080e7          	jalr	-106(ra) # 80000e10 <safestrcpy>
  pid = np->pid;
    80001e82:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e86:	854e                	mv	a0,s3
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	dee080e7          	jalr	-530(ra) # 80000c76 <release>
  acquire(&wait_lock);
    80001e90:	0000f497          	auipc	s1,0xf
    80001e94:	42848493          	addi	s1,s1,1064 # 800112b8 <wait_lock>
    80001e98:	8526                	mv	a0,s1
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	d28080e7          	jalr	-728(ra) # 80000bc2 <acquire>
  np->parent = p;
    80001ea2:	0559b823          	sd	s5,80(s3)
  release(&wait_lock);
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	dce080e7          	jalr	-562(ra) # 80000c76 <release>
  acquire(&np->lock);
    80001eb0:	854e                	mv	a0,s3
    80001eb2:	fffff097          	auipc	ra,0xfffff
    80001eb6:	d10080e7          	jalr	-752(ra) # 80000bc2 <acquire>
  np->state = RUNNABLE;
    80001eba:	478d                	li	a5,3
    80001ebc:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ec0:	854e                	mv	a0,s3
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	db4080e7          	jalr	-588(ra) # 80000c76 <release>
  np->traceMask = p->traceMask;
    80001eca:	034aa783          	lw	a5,52(s5)
    80001ece:	02f9aa23          	sw	a5,52(s3)
}
    80001ed2:	854a                	mv	a0,s2
    80001ed4:	70e2                	ld	ra,56(sp)
    80001ed6:	7442                	ld	s0,48(sp)
    80001ed8:	74a2                	ld	s1,40(sp)
    80001eda:	7902                	ld	s2,32(sp)
    80001edc:	69e2                	ld	s3,24(sp)
    80001ede:	6a42                	ld	s4,16(sp)
    80001ee0:	6aa2                	ld	s5,8(sp)
    80001ee2:	6121                	addi	sp,sp,64
    80001ee4:	8082                	ret
    return -1;
    80001ee6:	597d                	li	s2,-1
    80001ee8:	b7ed                	j	80001ed2 <fork+0x130>

0000000080001eea <scheduler>:
{
    80001eea:	715d                	addi	sp,sp,-80
    80001eec:	e486                	sd	ra,72(sp)
    80001eee:	e0a2                	sd	s0,64(sp)
    80001ef0:	fc26                	sd	s1,56(sp)
    80001ef2:	f84a                	sd	s2,48(sp)
    80001ef4:	f44e                	sd	s3,40(sp)
    80001ef6:	f052                	sd	s4,32(sp)
    80001ef8:	ec56                	sd	s5,24(sp)
    80001efa:	e85a                	sd	s6,16(sp)
    80001efc:	e45e                	sd	s7,8(sp)
    80001efe:	e062                	sd	s8,0(sp)
    80001f00:	0880                	addi	s0,sp,80
    80001f02:	8792                	mv	a5,tp
  int id = r_tp();
    80001f04:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f06:	00779b13          	slli	s6,a5,0x7
    80001f0a:	0000f717          	auipc	a4,0xf
    80001f0e:	39670713          	addi	a4,a4,918 # 800112a0 <pid_lock>
    80001f12:	975a                	add	a4,a4,s6
    80001f14:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f18:	0000f717          	auipc	a4,0xf
    80001f1c:	3c070713          	addi	a4,a4,960 # 800112d8 <cpus+0x8>
    80001f20:	9b3a                	add	s6,s6,a4
      if (p->state == RUNNABLE)
    80001f22:	498d                	li	s3,3
        p->state = RUNNING;
    80001f24:	4b91                	li	s7,4
        c->proc = p;
    80001f26:	079e                	slli	a5,a5,0x7
    80001f28:	0000fa17          	auipc	s4,0xf
    80001f2c:	378a0a13          	addi	s4,s4,888 # 800112a0 <pid_lock>
    80001f30:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    80001f32:	00015917          	auipc	s2,0x15
    80001f36:	79e90913          	addi	s2,s2,1950 # 800176d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f42:	10079073          	csrw	sstatus,a5
    80001f46:	0000f497          	auipc	s1,0xf
    80001f4a:	78a48493          	addi	s1,s1,1930 # 800116d0 <proc>
        p->average_bursttime = (ALPHA*curr_burst) + (((100-ALPHA)*avg)/100);
    80001f4e:	03200a93          	li	s5,50
    80001f52:	a811                	j	80001f66 <scheduler+0x7c>
      release(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	d20080e7          	jalr	-736(ra) # 80000c76 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f5e:	18048493          	addi	s1,s1,384
    80001f62:	fd248ce3          	beq	s1,s2,80001f3a <scheduler+0x50>
      acquire(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	c5a080e7          	jalr	-934(ra) # 80000bc2 <acquire>
      if (p->state == RUNNABLE)
    80001f70:	4c9c                	lw	a5,24(s1)
    80001f72:	ff3791e3          	bne	a5,s3,80001f54 <scheduler+0x6a>
        p->state = RUNNING;
    80001f76:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f7a:	029a3823          	sd	s1,48(s4)
        int old_runtime = p->runtime;
    80001f7e:	0484ac03          	lw	s8,72(s1)
        swtch(&c->context, &p->context);
    80001f82:	07848593          	addi	a1,s1,120
    80001f86:	855a                	mv	a0,s6
    80001f88:	00001097          	auipc	ra,0x1
    80001f8c:	874080e7          	jalr	-1932(ra) # 800027fc <swtch>
        int curr_burst = p->runtime - old_runtime;
    80001f90:	44bc                	lw	a5,72(s1)
    80001f92:	418787bb          	subw	a5,a5,s8
        p->average_bursttime = (ALPHA*curr_burst) + (((100-ALPHA)*avg)/100);
    80001f96:	035787bb          	mulw	a5,a5,s5
    80001f9a:	44f4                	lw	a3,76(s1)
    80001f9c:	01f6d71b          	srliw	a4,a3,0x1f
    80001fa0:	9f35                	addw	a4,a4,a3
    80001fa2:	4017571b          	sraiw	a4,a4,0x1
    80001fa6:	9fb9                	addw	a5,a5,a4
    80001fa8:	c4fc                	sw	a5,76(s1)
        c->proc = 0;
    80001faa:	020a3823          	sd	zero,48(s4)
    80001fae:	b75d                	j	80001f54 <scheduler+0x6a>

0000000080001fb0 <sched>:
{
    80001fb0:	7179                	addi	sp,sp,-48
    80001fb2:	f406                	sd	ra,40(sp)
    80001fb4:	f022                	sd	s0,32(sp)
    80001fb6:	ec26                	sd	s1,24(sp)
    80001fb8:	e84a                	sd	s2,16(sp)
    80001fba:	e44e                	sd	s3,8(sp)
    80001fbc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	9d4080e7          	jalr	-1580(ra) # 80001992 <myproc>
    80001fc6:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	b80080e7          	jalr	-1152(ra) # 80000b48 <holding>
    80001fd0:	c93d                	beqz	a0,80002046 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fd2:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80001fd4:	2781                	sext.w	a5,a5
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	0000f717          	auipc	a4,0xf
    80001fdc:	2c870713          	addi	a4,a4,712 # 800112a0 <pid_lock>
    80001fe0:	97ba                	add	a5,a5,a4
    80001fe2:	0a87a703          	lw	a4,168(a5)
    80001fe6:	4785                	li	a5,1
    80001fe8:	06f71763          	bne	a4,a5,80002056 <sched+0xa6>
  if (p->state == RUNNING)
    80001fec:	4c98                	lw	a4,24(s1)
    80001fee:	4791                	li	a5,4
    80001ff0:	06f70b63          	beq	a4,a5,80002066 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ff4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001ff8:	8b89                	andi	a5,a5,2
  if (intr_get())
    80001ffa:	efb5                	bnez	a5,80002076 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ffe:	0000f917          	auipc	s2,0xf
    80002002:	2a290913          	addi	s2,s2,674 # 800112a0 <pid_lock>
    80002006:	2781                	sext.w	a5,a5
    80002008:	079e                	slli	a5,a5,0x7
    8000200a:	97ca                	add	a5,a5,s2
    8000200c:	0ac7a983          	lw	s3,172(a5)
    80002010:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002012:	2781                	sext.w	a5,a5
    80002014:	079e                	slli	a5,a5,0x7
    80002016:	0000f597          	auipc	a1,0xf
    8000201a:	2c258593          	addi	a1,a1,706 # 800112d8 <cpus+0x8>
    8000201e:	95be                	add	a1,a1,a5
    80002020:	07848513          	addi	a0,s1,120
    80002024:	00000097          	auipc	ra,0x0
    80002028:	7d8080e7          	jalr	2008(ra) # 800027fc <swtch>
    8000202c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000202e:	2781                	sext.w	a5,a5
    80002030:	079e                	slli	a5,a5,0x7
    80002032:	97ca                	add	a5,a5,s2
    80002034:	0b37a623          	sw	s3,172(a5)
}
    80002038:	70a2                	ld	ra,40(sp)
    8000203a:	7402                	ld	s0,32(sp)
    8000203c:	64e2                	ld	s1,24(sp)
    8000203e:	6942                	ld	s2,16(sp)
    80002040:	69a2                	ld	s3,8(sp)
    80002042:	6145                	addi	sp,sp,48
    80002044:	8082                	ret
    panic("sched p->lock");
    80002046:	00006517          	auipc	a0,0x6
    8000204a:	1ba50513          	addi	a0,a0,442 # 80008200 <digits+0x1c0>
    8000204e:	ffffe097          	auipc	ra,0xffffe
    80002052:	4dc080e7          	jalr	1244(ra) # 8000052a <panic>
    panic("sched locks");
    80002056:	00006517          	auipc	a0,0x6
    8000205a:	1ba50513          	addi	a0,a0,442 # 80008210 <digits+0x1d0>
    8000205e:	ffffe097          	auipc	ra,0xffffe
    80002062:	4cc080e7          	jalr	1228(ra) # 8000052a <panic>
    panic("sched running");
    80002066:	00006517          	auipc	a0,0x6
    8000206a:	1ba50513          	addi	a0,a0,442 # 80008220 <digits+0x1e0>
    8000206e:	ffffe097          	auipc	ra,0xffffe
    80002072:	4bc080e7          	jalr	1212(ra) # 8000052a <panic>
    panic("sched interruptible");
    80002076:	00006517          	auipc	a0,0x6
    8000207a:	1ba50513          	addi	a0,a0,442 # 80008230 <digits+0x1f0>
    8000207e:	ffffe097          	auipc	ra,0xffffe
    80002082:	4ac080e7          	jalr	1196(ra) # 8000052a <panic>

0000000080002086 <yield>:
{
    80002086:	1101                	addi	sp,sp,-32
    80002088:	ec06                	sd	ra,24(sp)
    8000208a:	e822                	sd	s0,16(sp)
    8000208c:	e426                	sd	s1,8(sp)
    8000208e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002090:	00000097          	auipc	ra,0x0
    80002094:	902080e7          	jalr	-1790(ra) # 80001992 <myproc>
    80002098:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	b28080e7          	jalr	-1240(ra) # 80000bc2 <acquire>
  p->state = RUNNABLE;
    800020a2:	478d                	li	a5,3
    800020a4:	cc9c                	sw	a5,24(s1)
  sched();
    800020a6:	00000097          	auipc	ra,0x0
    800020aa:	f0a080e7          	jalr	-246(ra) # 80001fb0 <sched>
  release(&p->lock);
    800020ae:	8526                	mv	a0,s1
    800020b0:	fffff097          	auipc	ra,0xfffff
    800020b4:	bc6080e7          	jalr	-1082(ra) # 80000c76 <release>
}
    800020b8:	60e2                	ld	ra,24(sp)
    800020ba:	6442                	ld	s0,16(sp)
    800020bc:	64a2                	ld	s1,8(sp)
    800020be:	6105                	addi	sp,sp,32
    800020c0:	8082                	ret

00000000800020c2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800020c2:	7179                	addi	sp,sp,-48
    800020c4:	f406                	sd	ra,40(sp)
    800020c6:	f022                	sd	s0,32(sp)
    800020c8:	ec26                	sd	s1,24(sp)
    800020ca:	e84a                	sd	s2,16(sp)
    800020cc:	e44e                	sd	s3,8(sp)
    800020ce:	1800                	addi	s0,sp,48
    800020d0:	89aa                	mv	s3,a0
    800020d2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	8be080e7          	jalr	-1858(ra) # 80001992 <myproc>
    800020dc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); //DOC: sleeplock1
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	ae4080e7          	jalr	-1308(ra) # 80000bc2 <acquire>
  release(lk);
    800020e6:	854a                	mv	a0,s2
    800020e8:	fffff097          	auipc	ra,0xfffff
    800020ec:	b8e080e7          	jalr	-1138(ra) # 80000c76 <release>

  // Go to sleep.
  p->chan = chan;
    800020f0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020f4:	4789                	li	a5,2
    800020f6:	cc9c                	sw	a5,24(s1)

  sched();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	eb8080e7          	jalr	-328(ra) # 80001fb0 <sched>

  // Tidy up.
  p->chan = 0;
    80002100:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002104:	8526                	mv	a0,s1
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	b70080e7          	jalr	-1168(ra) # 80000c76 <release>
  acquire(lk);
    8000210e:	854a                	mv	a0,s2
    80002110:	fffff097          	auipc	ra,0xfffff
    80002114:	ab2080e7          	jalr	-1358(ra) # 80000bc2 <acquire>
}
    80002118:	70a2                	ld	ra,40(sp)
    8000211a:	7402                	ld	s0,32(sp)
    8000211c:	64e2                	ld	s1,24(sp)
    8000211e:	6942                	ld	s2,16(sp)
    80002120:	69a2                	ld	s3,8(sp)
    80002122:	6145                	addi	sp,sp,48
    80002124:	8082                	ret

0000000080002126 <wait>:
{
    80002126:	715d                	addi	sp,sp,-80
    80002128:	e486                	sd	ra,72(sp)
    8000212a:	e0a2                	sd	s0,64(sp)
    8000212c:	fc26                	sd	s1,56(sp)
    8000212e:	f84a                	sd	s2,48(sp)
    80002130:	f44e                	sd	s3,40(sp)
    80002132:	f052                	sd	s4,32(sp)
    80002134:	ec56                	sd	s5,24(sp)
    80002136:	e85a                	sd	s6,16(sp)
    80002138:	e45e                	sd	s7,8(sp)
    8000213a:	e062                	sd	s8,0(sp)
    8000213c:	0880                	addi	s0,sp,80
    8000213e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002140:	00000097          	auipc	ra,0x0
    80002144:	852080e7          	jalr	-1966(ra) # 80001992 <myproc>
    80002148:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000214a:	0000f517          	auipc	a0,0xf
    8000214e:	16e50513          	addi	a0,a0,366 # 800112b8 <wait_lock>
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a70080e7          	jalr	-1424(ra) # 80000bc2 <acquire>
    havekids = 0;
    8000215a:	4b81                	li	s7,0
        if (np->state == ZOMBIE)
    8000215c:	4a15                	li	s4,5
        havekids = 1;
    8000215e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002160:	00015997          	auipc	s3,0x15
    80002164:	57098993          	addi	s3,s3,1392 # 800176d0 <tickslock>
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002168:	0000fc17          	auipc	s8,0xf
    8000216c:	150c0c13          	addi	s8,s8,336 # 800112b8 <wait_lock>
    havekids = 0;
    80002170:	875e                	mv	a4,s7
    for (np = proc; np < &proc[NPROC]; np++)
    80002172:	0000f497          	auipc	s1,0xf
    80002176:	55e48493          	addi	s1,s1,1374 # 800116d0 <proc>
    8000217a:	a0bd                	j	800021e8 <wait+0xc2>
          pid = np->pid;
    8000217c:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002180:	000b0e63          	beqz	s6,8000219c <wait+0x76>
    80002184:	4691                	li	a3,4
    80002186:	02c48613          	addi	a2,s1,44
    8000218a:	85da                	mv	a1,s6
    8000218c:	06893503          	ld	a0,104(s2)
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	4ae080e7          	jalr	1198(ra) # 8000163e <copyout>
    80002198:	02054563          	bltz	a0,800021c2 <wait+0x9c>
          freeproc(np);
    8000219c:	8526                	mv	a0,s1
    8000219e:	00000097          	auipc	ra,0x0
    800021a2:	9a6080e7          	jalr	-1626(ra) # 80001b44 <freeproc>
          release(&np->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	ace080e7          	jalr	-1330(ra) # 80000c76 <release>
          release(&wait_lock);
    800021b0:	0000f517          	auipc	a0,0xf
    800021b4:	10850513          	addi	a0,a0,264 # 800112b8 <wait_lock>
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	abe080e7          	jalr	-1346(ra) # 80000c76 <release>
          return pid;
    800021c0:	a09d                	j	80002226 <wait+0x100>
            release(&np->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ab2080e7          	jalr	-1358(ra) # 80000c76 <release>
            release(&wait_lock);
    800021cc:	0000f517          	auipc	a0,0xf
    800021d0:	0ec50513          	addi	a0,a0,236 # 800112b8 <wait_lock>
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	aa2080e7          	jalr	-1374(ra) # 80000c76 <release>
            return -1;
    800021dc:	59fd                	li	s3,-1
    800021de:	a0a1                	j	80002226 <wait+0x100>
    for (np = proc; np < &proc[NPROC]; np++)
    800021e0:	18048493          	addi	s1,s1,384
    800021e4:	03348463          	beq	s1,s3,8000220c <wait+0xe6>
      if (np->parent == p)
    800021e8:	68bc                	ld	a5,80(s1)
    800021ea:	ff279be3          	bne	a5,s2,800021e0 <wait+0xba>
        acquire(&np->lock);
    800021ee:	8526                	mv	a0,s1
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	9d2080e7          	jalr	-1582(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800021f8:	4c9c                	lw	a5,24(s1)
    800021fa:	f94781e3          	beq	a5,s4,8000217c <wait+0x56>
        release(&np->lock);
    800021fe:	8526                	mv	a0,s1
    80002200:	fffff097          	auipc	ra,0xfffff
    80002204:	a76080e7          	jalr	-1418(ra) # 80000c76 <release>
        havekids = 1;
    80002208:	8756                	mv	a4,s5
    8000220a:	bfd9                	j	800021e0 <wait+0xba>
    if (!havekids || p->killed)
    8000220c:	c701                	beqz	a4,80002214 <wait+0xee>
    8000220e:	02892783          	lw	a5,40(s2)
    80002212:	c79d                	beqz	a5,80002240 <wait+0x11a>
      release(&wait_lock);
    80002214:	0000f517          	auipc	a0,0xf
    80002218:	0a450513          	addi	a0,a0,164 # 800112b8 <wait_lock>
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a5a080e7          	jalr	-1446(ra) # 80000c76 <release>
      return -1;
    80002224:	59fd                	li	s3,-1
}
    80002226:	854e                	mv	a0,s3
    80002228:	60a6                	ld	ra,72(sp)
    8000222a:	6406                	ld	s0,64(sp)
    8000222c:	74e2                	ld	s1,56(sp)
    8000222e:	7942                	ld	s2,48(sp)
    80002230:	79a2                	ld	s3,40(sp)
    80002232:	7a02                	ld	s4,32(sp)
    80002234:	6ae2                	ld	s5,24(sp)
    80002236:	6b42                	ld	s6,16(sp)
    80002238:	6ba2                	ld	s7,8(sp)
    8000223a:	6c02                	ld	s8,0(sp)
    8000223c:	6161                	addi	sp,sp,80
    8000223e:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002240:	85e2                	mv	a1,s8
    80002242:	854a                	mv	a0,s2
    80002244:	00000097          	auipc	ra,0x0
    80002248:	e7e080e7          	jalr	-386(ra) # 800020c2 <sleep>
    havekids = 0;
    8000224c:	b715                	j	80002170 <wait+0x4a>

000000008000224e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    8000224e:	7139                	addi	sp,sp,-64
    80002250:	fc06                	sd	ra,56(sp)
    80002252:	f822                	sd	s0,48(sp)
    80002254:	f426                	sd	s1,40(sp)
    80002256:	f04a                	sd	s2,32(sp)
    80002258:	ec4e                	sd	s3,24(sp)
    8000225a:	e852                	sd	s4,16(sp)
    8000225c:	e456                	sd	s5,8(sp)
    8000225e:	0080                	addi	s0,sp,64
    80002260:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002262:	0000f497          	auipc	s1,0xf
    80002266:	46e48493          	addi	s1,s1,1134 # 800116d0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    8000226a:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    8000226c:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    8000226e:	00015917          	auipc	s2,0x15
    80002272:	46290913          	addi	s2,s2,1122 # 800176d0 <tickslock>
    80002276:	a811                	j	8000228a <wakeup+0x3c>
      }
      release(&p->lock);
    80002278:	8526                	mv	a0,s1
    8000227a:	fffff097          	auipc	ra,0xfffff
    8000227e:	9fc080e7          	jalr	-1540(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002282:	18048493          	addi	s1,s1,384
    80002286:	03248663          	beq	s1,s2,800022b2 <wakeup+0x64>
    if (p != myproc())
    8000228a:	fffff097          	auipc	ra,0xfffff
    8000228e:	708080e7          	jalr	1800(ra) # 80001992 <myproc>
    80002292:	fea488e3          	beq	s1,a0,80002282 <wakeup+0x34>
      acquire(&p->lock);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	92a080e7          	jalr	-1750(ra) # 80000bc2 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    800022a0:	4c9c                	lw	a5,24(s1)
    800022a2:	fd379be3          	bne	a5,s3,80002278 <wakeup+0x2a>
    800022a6:	709c                	ld	a5,32(s1)
    800022a8:	fd4798e3          	bne	a5,s4,80002278 <wakeup+0x2a>
        p->state = RUNNABLE;
    800022ac:	0154ac23          	sw	s5,24(s1)
    800022b0:	b7e1                	j	80002278 <wakeup+0x2a>
    }
  }
}
    800022b2:	70e2                	ld	ra,56(sp)
    800022b4:	7442                	ld	s0,48(sp)
    800022b6:	74a2                	ld	s1,40(sp)
    800022b8:	7902                	ld	s2,32(sp)
    800022ba:	69e2                	ld	s3,24(sp)
    800022bc:	6a42                	ld	s4,16(sp)
    800022be:	6aa2                	ld	s5,8(sp)
    800022c0:	6121                	addi	sp,sp,64
    800022c2:	8082                	ret

00000000800022c4 <reparent>:
{
    800022c4:	7179                	addi	sp,sp,-48
    800022c6:	f406                	sd	ra,40(sp)
    800022c8:	f022                	sd	s0,32(sp)
    800022ca:	ec26                	sd	s1,24(sp)
    800022cc:	e84a                	sd	s2,16(sp)
    800022ce:	e44e                	sd	s3,8(sp)
    800022d0:	e052                	sd	s4,0(sp)
    800022d2:	1800                	addi	s0,sp,48
    800022d4:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022d6:	0000f497          	auipc	s1,0xf
    800022da:	3fa48493          	addi	s1,s1,1018 # 800116d0 <proc>
      pp->parent = initproc;
    800022de:	00007a17          	auipc	s4,0x7
    800022e2:	d4aa0a13          	addi	s4,s4,-694 # 80009028 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022e6:	00015997          	auipc	s3,0x15
    800022ea:	3ea98993          	addi	s3,s3,1002 # 800176d0 <tickslock>
    800022ee:	a029                	j	800022f8 <reparent+0x34>
    800022f0:	18048493          	addi	s1,s1,384
    800022f4:	01348d63          	beq	s1,s3,8000230e <reparent+0x4a>
    if (pp->parent == p)
    800022f8:	68bc                	ld	a5,80(s1)
    800022fa:	ff279be3          	bne	a5,s2,800022f0 <reparent+0x2c>
      pp->parent = initproc;
    800022fe:	000a3503          	ld	a0,0(s4)
    80002302:	e8a8                	sd	a0,80(s1)
      wakeup(initproc);
    80002304:	00000097          	auipc	ra,0x0
    80002308:	f4a080e7          	jalr	-182(ra) # 8000224e <wakeup>
    8000230c:	b7d5                	j	800022f0 <reparent+0x2c>
}
    8000230e:	70a2                	ld	ra,40(sp)
    80002310:	7402                	ld	s0,32(sp)
    80002312:	64e2                	ld	s1,24(sp)
    80002314:	6942                	ld	s2,16(sp)
    80002316:	69a2                	ld	s3,8(sp)
    80002318:	6a02                	ld	s4,0(sp)
    8000231a:	6145                	addi	sp,sp,48
    8000231c:	8082                	ret

000000008000231e <exit>:
{
    8000231e:	7179                	addi	sp,sp,-48
    80002320:	f406                	sd	ra,40(sp)
    80002322:	f022                	sd	s0,32(sp)
    80002324:	ec26                	sd	s1,24(sp)
    80002326:	e84a                	sd	s2,16(sp)
    80002328:	e44e                	sd	s3,8(sp)
    8000232a:	e052                	sd	s4,0(sp)
    8000232c:	1800                	addi	s0,sp,48
    8000232e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	662080e7          	jalr	1634(ra) # 80001992 <myproc>
    80002338:	89aa                	mv	s3,a0
  acquire(&tickslock);
    8000233a:	00015517          	auipc	a0,0x15
    8000233e:	39650513          	addi	a0,a0,918 # 800176d0 <tickslock>
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	880080e7          	jalr	-1920(ra) # 80000bc2 <acquire>
  p->ttime = ticks;
    8000234a:	00007797          	auipc	a5,0x7
    8000234e:	ce67a783          	lw	a5,-794(a5) # 80009030 <ticks>
    80002352:	02f9ae23          	sw	a5,60(s3)
  release(&tickslock);
    80002356:	00015517          	auipc	a0,0x15
    8000235a:	37a50513          	addi	a0,a0,890 # 800176d0 <tickslock>
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	918080e7          	jalr	-1768(ra) # 80000c76 <release>
  if (p == initproc)
    80002366:	00007797          	auipc	a5,0x7
    8000236a:	cc27b783          	ld	a5,-830(a5) # 80009028 <initproc>
    8000236e:	0e898493          	addi	s1,s3,232
    80002372:	16898913          	addi	s2,s3,360
    80002376:	03379363          	bne	a5,s3,8000239c <exit+0x7e>
    panic("init exiting");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ece50513          	addi	a0,a0,-306 # 80008248 <digits+0x208>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1a8080e7          	jalr	424(ra) # 8000052a <panic>
      fileclose(f);
    8000238a:	00002097          	auipc	ra,0x2
    8000238e:	524080e7          	jalr	1316(ra) # 800048ae <fileclose>
      p->ofile[fd] = 0;
    80002392:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002396:	04a1                	addi	s1,s1,8
    80002398:	01248563          	beq	s1,s2,800023a2 <exit+0x84>
    if (p->ofile[fd])
    8000239c:	6088                	ld	a0,0(s1)
    8000239e:	f575                	bnez	a0,8000238a <exit+0x6c>
    800023a0:	bfdd                	j	80002396 <exit+0x78>
  begin_op();
    800023a2:	00002097          	auipc	ra,0x2
    800023a6:	040080e7          	jalr	64(ra) # 800043e2 <begin_op>
  iput(p->cwd);
    800023aa:	1689b503          	ld	a0,360(s3)
    800023ae:	00002097          	auipc	ra,0x2
    800023b2:	818080e7          	jalr	-2024(ra) # 80003bc6 <iput>
  end_op();
    800023b6:	00002097          	auipc	ra,0x2
    800023ba:	0ac080e7          	jalr	172(ra) # 80004462 <end_op>
  p->cwd = 0;
    800023be:	1609b423          	sd	zero,360(s3)
  acquire(&wait_lock);
    800023c2:	0000f497          	auipc	s1,0xf
    800023c6:	ef648493          	addi	s1,s1,-266 # 800112b8 <wait_lock>
    800023ca:	8526                	mv	a0,s1
    800023cc:	ffffe097          	auipc	ra,0xffffe
    800023d0:	7f6080e7          	jalr	2038(ra) # 80000bc2 <acquire>
  reparent(p);
    800023d4:	854e                	mv	a0,s3
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	eee080e7          	jalr	-274(ra) # 800022c4 <reparent>
  wakeup(p->parent);
    800023de:	0509b503          	ld	a0,80(s3)
    800023e2:	00000097          	auipc	ra,0x0
    800023e6:	e6c080e7          	jalr	-404(ra) # 8000224e <wakeup>
  acquire(&p->lock);
    800023ea:	854e                	mv	a0,s3
    800023ec:	ffffe097          	auipc	ra,0xffffe
    800023f0:	7d6080e7          	jalr	2006(ra) # 80000bc2 <acquire>
  p->xstate = status;
    800023f4:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023f8:	4795                	li	a5,5
    800023fa:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800023fe:	8526                	mv	a0,s1
    80002400:	fffff097          	auipc	ra,0xfffff
    80002404:	876080e7          	jalr	-1930(ra) # 80000c76 <release>
  sched();
    80002408:	00000097          	auipc	ra,0x0
    8000240c:	ba8080e7          	jalr	-1112(ra) # 80001fb0 <sched>
  panic("zombie exit");
    80002410:	00006517          	auipc	a0,0x6
    80002414:	e4850513          	addi	a0,a0,-440 # 80008258 <digits+0x218>
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	112080e7          	jalr	274(ra) # 8000052a <panic>

0000000080002420 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002420:	7179                	addi	sp,sp,-48
    80002422:	f406                	sd	ra,40(sp)
    80002424:	f022                	sd	s0,32(sp)
    80002426:	ec26                	sd	s1,24(sp)
    80002428:	e84a                	sd	s2,16(sp)
    8000242a:	e44e                	sd	s3,8(sp)
    8000242c:	1800                	addi	s0,sp,48
    8000242e:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002430:	0000f497          	auipc	s1,0xf
    80002434:	2a048493          	addi	s1,s1,672 # 800116d0 <proc>
    80002438:	00015997          	auipc	s3,0x15
    8000243c:	29898993          	addi	s3,s3,664 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	ffffe097          	auipc	ra,0xffffe
    80002446:	780080e7          	jalr	1920(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    8000244a:	589c                	lw	a5,48(s1)
    8000244c:	01278d63          	beq	a5,s2,80002466 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002450:	8526                	mv	a0,s1
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	824080e7          	jalr	-2012(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000245a:	18048493          	addi	s1,s1,384
    8000245e:	ff3491e3          	bne	s1,s3,80002440 <kill+0x20>
  }
  return -1;
    80002462:	557d                	li	a0,-1
    80002464:	a829                	j	8000247e <kill+0x5e>
      p->killed = 1;
    80002466:	4785                	li	a5,1
    80002468:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    8000246a:	4c98                	lw	a4,24(s1)
    8000246c:	4789                	li	a5,2
    8000246e:	00f70f63          	beq	a4,a5,8000248c <kill+0x6c>
      release(&p->lock);
    80002472:	8526                	mv	a0,s1
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	802080e7          	jalr	-2046(ra) # 80000c76 <release>
      return 0;
    8000247c:	4501                	li	a0,0
}
    8000247e:	70a2                	ld	ra,40(sp)
    80002480:	7402                	ld	s0,32(sp)
    80002482:	64e2                	ld	s1,24(sp)
    80002484:	6942                	ld	s2,16(sp)
    80002486:	69a2                	ld	s3,8(sp)
    80002488:	6145                	addi	sp,sp,48
    8000248a:	8082                	ret
        p->state = RUNNABLE;
    8000248c:	478d                	li	a5,3
    8000248e:	cc9c                	sw	a5,24(s1)
    80002490:	b7cd                	j	80002472 <kill+0x52>

0000000080002492 <wait_stat>:
int wait_stat(int* status, struct perf *performance){
    80002492:	711d                	addi	sp,sp,-96
    80002494:	ec86                	sd	ra,88(sp)
    80002496:	e8a2                	sd	s0,80(sp)
    80002498:	e4a6                	sd	s1,72(sp)
    8000249a:	e0ca                	sd	s2,64(sp)
    8000249c:	fc4e                	sd	s3,56(sp)
    8000249e:	f852                	sd	s4,48(sp)
    800024a0:	f456                	sd	s5,40(sp)
    800024a2:	f05a                	sd	s6,32(sp)
    800024a4:	ec5e                	sd	s7,24(sp)
    800024a6:	e862                	sd	s8,16(sp)
    800024a8:	e466                	sd	s9,8(sp)
    800024aa:	e06a                	sd	s10,0(sp)
    800024ac:	1080                	addi	s0,sp,96
    800024ae:	8c2a                	mv	s8,a0
    800024b0:	8bae                	mv	s7,a1
  //TODO: IMPLEMENT!
    struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	4e0080e7          	jalr	1248(ra) # 80001992 <myproc>
    800024ba:	892a                	mv	s2,a0
  //performance = (struct perf*)malloc(sizeof(performance));

  acquire(&wait_lock);
    800024bc:	0000f517          	auipc	a0,0xf
    800024c0:	dfc50513          	addi	a0,a0,-516 # 800112b8 <wait_lock>
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	6fe080e7          	jalr	1790(ra) # 80000bc2 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    800024cc:	4c81                	li	s9,0
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        printf("[PARENT proc.c]: found a child\n");
    800024ce:	00006a97          	auipc	s5,0x6
    800024d2:	d9aa8a93          	addi	s5,s5,-614 # 80008268 <digits+0x228>
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    800024d6:	4a15                	li	s4,5
        havekids = 1;
    800024d8:	4b05                	li	s6,1
    for (np = proc; np < &proc[NPROC]; np++)
    800024da:	00015997          	auipc	s3,0x15
    800024de:	1f698993          	addi	s3,s3,502 # 800176d0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); //DOC: wait-sleep
    800024e2:	0000fd17          	auipc	s10,0xf
    800024e6:	dd6d0d13          	addi	s10,s10,-554 # 800112b8 <wait_lock>
    havekids = 0;
    800024ea:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    800024ec:	0000f497          	auipc	s1,0xf
    800024f0:	1e448493          	addi	s1,s1,484 # 800116d0 <proc>
    800024f4:	a0f9                	j	800025c2 <wait_stat+0x130>
          printf("[PARENT proc.c]: copying performance values\n");
    800024f6:	00006517          	auipc	a0,0x6
    800024fa:	d9250513          	addi	a0,a0,-622 # 80008288 <digits+0x248>
    800024fe:	ffffe097          	auipc	ra,0xffffe
    80002502:	076080e7          	jalr	118(ra) # 80000574 <printf>
          pid = np->pid;
    80002506:	0304a983          	lw	s3,48(s1)
          printf("[PARENT proc.c]: pid = %d\n", pid);
    8000250a:	85ce                	mv	a1,s3
    8000250c:	00006517          	auipc	a0,0x6
    80002510:	dac50513          	addi	a0,a0,-596 # 800082b8 <digits+0x278>
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	060080e7          	jalr	96(ra) # 80000574 <printf>
          performance->ctime = np->ctime;//FAILS HERE
    8000251c:	5c8c                	lw	a1,56(s1)
    8000251e:	00bba023          	sw	a1,0(s7) # fffffffffffff000 <end+0xffffffff7ffd9000>
          printf("[PARENT proc.c]:ctime = %d\n", performance->ctime);
    80002522:	00006517          	auipc	a0,0x6
    80002526:	db650513          	addi	a0,a0,-586 # 800082d8 <digits+0x298>
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	04a080e7          	jalr	74(ra) # 80000574 <printf>
          performance->ttime = np->ttime;
    80002532:	5cdc                	lw	a5,60(s1)
    80002534:	00fba223          	sw	a5,4(s7)
          performance->retime = np->retime;
    80002538:	40fc                	lw	a5,68(s1)
    8000253a:	00fba623          	sw	a5,12(s7)
          performance->rutime = np->runtime;
    8000253e:	44bc                	lw	a5,72(s1)
    80002540:	00fba823          	sw	a5,16(s7)
          performance->average_bursttime = np->average_bursttime;
    80002544:	44fc                	lw	a5,76(s1)
    80002546:	00fbaa23          	sw	a5,20(s7)
          printf("[PARENT proc.c]: finished copying\n");
    8000254a:	00006517          	auipc	a0,0x6
    8000254e:	dae50513          	addi	a0,a0,-594 # 800082f8 <digits+0x2b8>
    80002552:	ffffe097          	auipc	ra,0xffffe
    80002556:	022080e7          	jalr	34(ra) # 80000574 <printf>
          if (status != 0 && copyout(p->pagetable, (uint64)status, (char *)&np->xstate,
    8000255a:	000c0e63          	beqz	s8,80002576 <wait_stat+0xe4>
    8000255e:	4691                	li	a3,4
    80002560:	02c48613          	addi	a2,s1,44
    80002564:	85e2                	mv	a1,s8
    80002566:	06893503          	ld	a0,104(s2)
    8000256a:	fffff097          	auipc	ra,0xfffff
    8000256e:	0d4080e7          	jalr	212(ra) # 8000163e <copyout>
    80002572:	02054563          	bltz	a0,8000259c <wait_stat+0x10a>
          freeproc(np);
    80002576:	8526                	mv	a0,s1
    80002578:	fffff097          	auipc	ra,0xfffff
    8000257c:	5cc080e7          	jalr	1484(ra) # 80001b44 <freeproc>
          release(&np->lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	6f4080e7          	jalr	1780(ra) # 80000c76 <release>
          release(&wait_lock);
    8000258a:	0000f517          	auipc	a0,0xf
    8000258e:	d2e50513          	addi	a0,a0,-722 # 800112b8 <wait_lock>
    80002592:	ffffe097          	auipc	ra,0xffffe
    80002596:	6e4080e7          	jalr	1764(ra) # 80000c76 <release>
          return pid;
    8000259a:	a885                	j	8000260a <wait_stat+0x178>
            release(&np->lock);
    8000259c:	8526                	mv	a0,s1
    8000259e:	ffffe097          	auipc	ra,0xffffe
    800025a2:	6d8080e7          	jalr	1752(ra) # 80000c76 <release>
            release(&wait_lock);
    800025a6:	0000f517          	auipc	a0,0xf
    800025aa:	d1250513          	addi	a0,a0,-750 # 800112b8 <wait_lock>
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	6c8080e7          	jalr	1736(ra) # 80000c76 <release>
            return -1;
    800025b6:	59fd                	li	s3,-1
    800025b8:	a889                	j	8000260a <wait_stat+0x178>
    for (np = proc; np < &proc[NPROC]; np++)
    800025ba:	18048493          	addi	s1,s1,384
    800025be:	03348963          	beq	s1,s3,800025f0 <wait_stat+0x15e>
      if (np->parent == p)
    800025c2:	68bc                	ld	a5,80(s1)
    800025c4:	ff279be3          	bne	a5,s2,800025ba <wait_stat+0x128>
        printf("[PARENT proc.c]: found a child\n");
    800025c8:	8556                	mv	a0,s5
    800025ca:	ffffe097          	auipc	ra,0xffffe
    800025ce:	faa080e7          	jalr	-86(ra) # 80000574 <printf>
        acquire(&np->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	5ee080e7          	jalr	1518(ra) # 80000bc2 <acquire>
        if (np->state == ZOMBIE)
    800025dc:	4c9c                	lw	a5,24(s1)
    800025de:	f1478ce3          	beq	a5,s4,800024f6 <wait_stat+0x64>
        release(&np->lock);
    800025e2:	8526                	mv	a0,s1
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	692080e7          	jalr	1682(ra) # 80000c76 <release>
        havekids = 1;
    800025ec:	875a                	mv	a4,s6
    800025ee:	b7f1                	j	800025ba <wait_stat+0x128>
    if (!havekids || p->killed)
    800025f0:	c701                	beqz	a4,800025f8 <wait_stat+0x166>
    800025f2:	02892783          	lw	a5,40(s2)
    800025f6:	cb8d                	beqz	a5,80002628 <wait_stat+0x196>
      release(&wait_lock);
    800025f8:	0000f517          	auipc	a0,0xf
    800025fc:	cc050513          	addi	a0,a0,-832 # 800112b8 <wait_lock>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	676080e7          	jalr	1654(ra) # 80000c76 <release>
      return -1;
    80002608:	59fd                	li	s3,-1
  }
}
    8000260a:	854e                	mv	a0,s3
    8000260c:	60e6                	ld	ra,88(sp)
    8000260e:	6446                	ld	s0,80(sp)
    80002610:	64a6                	ld	s1,72(sp)
    80002612:	6906                	ld	s2,64(sp)
    80002614:	79e2                	ld	s3,56(sp)
    80002616:	7a42                	ld	s4,48(sp)
    80002618:	7aa2                	ld	s5,40(sp)
    8000261a:	7b02                	ld	s6,32(sp)
    8000261c:	6be2                	ld	s7,24(sp)
    8000261e:	6c42                	ld	s8,16(sp)
    80002620:	6ca2                	ld	s9,8(sp)
    80002622:	6d02                	ld	s10,0(sp)
    80002624:	6125                	addi	sp,sp,96
    80002626:	8082                	ret
    sleep(p, &wait_lock); //DOC: wait-sleep
    80002628:	85ea                	mv	a1,s10
    8000262a:	854a                	mv	a0,s2
    8000262c:	00000097          	auipc	ra,0x0
    80002630:	a96080e7          	jalr	-1386(ra) # 800020c2 <sleep>
    havekids = 0;
    80002634:	bd5d                	j	800024ea <wait_stat+0x58>

0000000080002636 <trace>:
int trace(int mask, int pid)
{
    80002636:	7179                	addi	sp,sp,-48
    80002638:	f406                	sd	ra,40(sp)
    8000263a:	f022                	sd	s0,32(sp)
    8000263c:	ec26                	sd	s1,24(sp)
    8000263e:	e84a                	sd	s2,16(sp)
    80002640:	e44e                	sd	s3,8(sp)
    80002642:	e052                	sd	s4,0(sp)
    80002644:	1800                	addi	s0,sp,48
    80002646:	8a2a                	mv	s4,a0
    80002648:	892e                	mv	s2,a1
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    8000264a:	0000f497          	auipc	s1,0xf
    8000264e:	08648493          	addi	s1,s1,134 # 800116d0 <proc>
    80002652:	00015997          	auipc	s3,0x15
    80002656:	07e98993          	addi	s3,s3,126 # 800176d0 <tickslock>
  {
    acquire(&p->lock);
    8000265a:	8526                	mv	a0,s1
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	566080e7          	jalr	1382(ra) # 80000bc2 <acquire>
    if (p->pid == pid)
    80002664:	589c                	lw	a5,48(s1)
    80002666:	01278d63          	beq	a5,s2,80002680 <trace+0x4a>
    {
      p->traceMask = mask;
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000266a:	8526                	mv	a0,s1
    8000266c:	ffffe097          	auipc	ra,0xffffe
    80002670:	60a080e7          	jalr	1546(ra) # 80000c76 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002674:	18048493          	addi	s1,s1,384
    80002678:	ff3491e3          	bne	s1,s3,8000265a <trace+0x24>
  }
  return -1;
    8000267c:	557d                	li	a0,-1
    8000267e:	a809                	j	80002690 <trace+0x5a>
      p->traceMask = mask;
    80002680:	0344aa23          	sw	s4,52(s1)
      release(&p->lock);
    80002684:	8526                	mv	a0,s1
    80002686:	ffffe097          	auipc	ra,0xffffe
    8000268a:	5f0080e7          	jalr	1520(ra) # 80000c76 <release>
      return 0;
    8000268e:	4501                	li	a0,0
}
    80002690:	70a2                	ld	ra,40(sp)
    80002692:	7402                	ld	s0,32(sp)
    80002694:	64e2                	ld	s1,24(sp)
    80002696:	6942                	ld	s2,16(sp)
    80002698:	69a2                	ld	s3,8(sp)
    8000269a:	6a02                	ld	s4,0(sp)
    8000269c:	6145                	addi	sp,sp,48
    8000269e:	8082                	ret

00000000800026a0 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800026a0:	7179                	addi	sp,sp,-48
    800026a2:	f406                	sd	ra,40(sp)
    800026a4:	f022                	sd	s0,32(sp)
    800026a6:	ec26                	sd	s1,24(sp)
    800026a8:	e84a                	sd	s2,16(sp)
    800026aa:	e44e                	sd	s3,8(sp)
    800026ac:	e052                	sd	s4,0(sp)
    800026ae:	1800                	addi	s0,sp,48
    800026b0:	84aa                	mv	s1,a0
    800026b2:	892e                	mv	s2,a1
    800026b4:	89b2                	mv	s3,a2
    800026b6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026b8:	fffff097          	auipc	ra,0xfffff
    800026bc:	2da080e7          	jalr	730(ra) # 80001992 <myproc>
  if (user_dst)
    800026c0:	c08d                	beqz	s1,800026e2 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800026c2:	86d2                	mv	a3,s4
    800026c4:	864e                	mv	a2,s3
    800026c6:	85ca                	mv	a1,s2
    800026c8:	7528                	ld	a0,104(a0)
    800026ca:	fffff097          	auipc	ra,0xfffff
    800026ce:	f74080e7          	jalr	-140(ra) # 8000163e <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026d2:	70a2                	ld	ra,40(sp)
    800026d4:	7402                	ld	s0,32(sp)
    800026d6:	64e2                	ld	s1,24(sp)
    800026d8:	6942                	ld	s2,16(sp)
    800026da:	69a2                	ld	s3,8(sp)
    800026dc:	6a02                	ld	s4,0(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret
    memmove((char *)dst, src, len);
    800026e2:	000a061b          	sext.w	a2,s4
    800026e6:	85ce                	mv	a1,s3
    800026e8:	854a                	mv	a0,s2
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	630080e7          	jalr	1584(ra) # 80000d1a <memmove>
    return 0;
    800026f2:	8526                	mv	a0,s1
    800026f4:	bff9                	j	800026d2 <either_copyout+0x32>

00000000800026f6 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026f6:	7179                	addi	sp,sp,-48
    800026f8:	f406                	sd	ra,40(sp)
    800026fa:	f022                	sd	s0,32(sp)
    800026fc:	ec26                	sd	s1,24(sp)
    800026fe:	e84a                	sd	s2,16(sp)
    80002700:	e44e                	sd	s3,8(sp)
    80002702:	e052                	sd	s4,0(sp)
    80002704:	1800                	addi	s0,sp,48
    80002706:	892a                	mv	s2,a0
    80002708:	84ae                	mv	s1,a1
    8000270a:	89b2                	mv	s3,a2
    8000270c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	284080e7          	jalr	644(ra) # 80001992 <myproc>
  if (user_src)
    80002716:	c08d                	beqz	s1,80002738 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002718:	86d2                	mv	a3,s4
    8000271a:	864e                	mv	a2,s3
    8000271c:	85ca                	mv	a1,s2
    8000271e:	7528                	ld	a0,104(a0)
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	faa080e7          	jalr	-86(ra) # 800016ca <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002728:	70a2                	ld	ra,40(sp)
    8000272a:	7402                	ld	s0,32(sp)
    8000272c:	64e2                	ld	s1,24(sp)
    8000272e:	6942                	ld	s2,16(sp)
    80002730:	69a2                	ld	s3,8(sp)
    80002732:	6a02                	ld	s4,0(sp)
    80002734:	6145                	addi	sp,sp,48
    80002736:	8082                	ret
    memmove(dst, (char *)src, len);
    80002738:	000a061b          	sext.w	a2,s4
    8000273c:	85ce                	mv	a1,s3
    8000273e:	854a                	mv	a0,s2
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	5da080e7          	jalr	1498(ra) # 80000d1a <memmove>
    return 0;
    80002748:	8526                	mv	a0,s1
    8000274a:	bff9                	j	80002728 <either_copyin+0x32>

000000008000274c <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000274c:	715d                	addi	sp,sp,-80
    8000274e:	e486                	sd	ra,72(sp)
    80002750:	e0a2                	sd	s0,64(sp)
    80002752:	fc26                	sd	s1,56(sp)
    80002754:	f84a                	sd	s2,48(sp)
    80002756:	f44e                	sd	s3,40(sp)
    80002758:	f052                	sd	s4,32(sp)
    8000275a:	ec56                	sd	s5,24(sp)
    8000275c:	e85a                	sd	s6,16(sp)
    8000275e:	e45e                	sd	s7,8(sp)
    80002760:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002762:	00006517          	auipc	a0,0x6
    80002766:	96650513          	addi	a0,a0,-1690 # 800080c8 <digits+0x88>
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	e0a080e7          	jalr	-502(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002772:	0000f497          	auipc	s1,0xf
    80002776:	0ce48493          	addi	s1,s1,206 # 80011840 <proc+0x170>
    8000277a:	00015917          	auipc	s2,0x15
    8000277e:	0c690913          	addi	s2,s2,198 # 80017840 <bcache+0x158>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002782:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002784:	00006997          	auipc	s3,0x6
    80002788:	b9c98993          	addi	s3,s3,-1124 # 80008320 <digits+0x2e0>
    printf("%d %s %s", p->pid, state, p->name);
    8000278c:	00006a97          	auipc	s5,0x6
    80002790:	b9ca8a93          	addi	s5,s5,-1124 # 80008328 <digits+0x2e8>
    printf("\n");
    80002794:	00006a17          	auipc	s4,0x6
    80002798:	934a0a13          	addi	s4,s4,-1740 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000279c:	00006b97          	auipc	s7,0x6
    800027a0:	bc4b8b93          	addi	s7,s7,-1084 # 80008360 <states.0>
    800027a4:	a00d                	j	800027c6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800027a6:	ec06a583          	lw	a1,-320(a3)
    800027aa:	8556                	mv	a0,s5
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	dc8080e7          	jalr	-568(ra) # 80000574 <printf>
    printf("\n");
    800027b4:	8552                	mv	a0,s4
    800027b6:	ffffe097          	auipc	ra,0xffffe
    800027ba:	dbe080e7          	jalr	-578(ra) # 80000574 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800027be:	18048493          	addi	s1,s1,384
    800027c2:	03248263          	beq	s1,s2,800027e6 <procdump+0x9a>
    if (p->state == UNUSED)
    800027c6:	86a6                	mv	a3,s1
    800027c8:	ea84a783          	lw	a5,-344(s1)
    800027cc:	dbed                	beqz	a5,800027be <procdump+0x72>
      state = "???";
    800027ce:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027d0:	fcfb6be3          	bltu	s6,a5,800027a6 <procdump+0x5a>
    800027d4:	02079713          	slli	a4,a5,0x20
    800027d8:	01d75793          	srli	a5,a4,0x1d
    800027dc:	97de                	add	a5,a5,s7
    800027de:	6390                	ld	a2,0(a5)
    800027e0:	f279                	bnez	a2,800027a6 <procdump+0x5a>
      state = "???";
    800027e2:	864e                	mv	a2,s3
    800027e4:	b7c9                	j	800027a6 <procdump+0x5a>
  }
}
    800027e6:	60a6                	ld	ra,72(sp)
    800027e8:	6406                	ld	s0,64(sp)
    800027ea:	74e2                	ld	s1,56(sp)
    800027ec:	7942                	ld	s2,48(sp)
    800027ee:	79a2                	ld	s3,40(sp)
    800027f0:	7a02                	ld	s4,32(sp)
    800027f2:	6ae2                	ld	s5,24(sp)
    800027f4:	6b42                	ld	s6,16(sp)
    800027f6:	6ba2                	ld	s7,8(sp)
    800027f8:	6161                	addi	sp,sp,80
    800027fa:	8082                	ret

00000000800027fc <swtch>:
    800027fc:	00153023          	sd	ra,0(a0)
    80002800:	00253423          	sd	sp,8(a0)
    80002804:	e900                	sd	s0,16(a0)
    80002806:	ed04                	sd	s1,24(a0)
    80002808:	03253023          	sd	s2,32(a0)
    8000280c:	03353423          	sd	s3,40(a0)
    80002810:	03453823          	sd	s4,48(a0)
    80002814:	03553c23          	sd	s5,56(a0)
    80002818:	05653023          	sd	s6,64(a0)
    8000281c:	05753423          	sd	s7,72(a0)
    80002820:	05853823          	sd	s8,80(a0)
    80002824:	05953c23          	sd	s9,88(a0)
    80002828:	07a53023          	sd	s10,96(a0)
    8000282c:	07b53423          	sd	s11,104(a0)
    80002830:	0005b083          	ld	ra,0(a1)
    80002834:	0085b103          	ld	sp,8(a1)
    80002838:	6980                	ld	s0,16(a1)
    8000283a:	6d84                	ld	s1,24(a1)
    8000283c:	0205b903          	ld	s2,32(a1)
    80002840:	0285b983          	ld	s3,40(a1)
    80002844:	0305ba03          	ld	s4,48(a1)
    80002848:	0385ba83          	ld	s5,56(a1)
    8000284c:	0405bb03          	ld	s6,64(a1)
    80002850:	0485bb83          	ld	s7,72(a1)
    80002854:	0505bc03          	ld	s8,80(a1)
    80002858:	0585bc83          	ld	s9,88(a1)
    8000285c:	0605bd03          	ld	s10,96(a1)
    80002860:	0685bd83          	ld	s11,104(a1)
    80002864:	8082                	ret

0000000080002866 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002866:	1141                	addi	sp,sp,-16
    80002868:	e406                	sd	ra,8(sp)
    8000286a:	e022                	sd	s0,0(sp)
    8000286c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000286e:	00006597          	auipc	a1,0x6
    80002872:	b2258593          	addi	a1,a1,-1246 # 80008390 <states.0+0x30>
    80002876:	00015517          	auipc	a0,0x15
    8000287a:	e5a50513          	addi	a0,a0,-422 # 800176d0 <tickslock>
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	2b4080e7          	jalr	692(ra) # 80000b32 <initlock>
}
    80002886:	60a2                	ld	ra,8(sp)
    80002888:	6402                	ld	s0,0(sp)
    8000288a:	0141                	addi	sp,sp,16
    8000288c:	8082                	ret

000000008000288e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000288e:	1141                	addi	sp,sp,-16
    80002890:	e422                	sd	s0,8(sp)
    80002892:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002894:	00003797          	auipc	a5,0x3
    80002898:	63c78793          	addi	a5,a5,1596 # 80005ed0 <kernelvec>
    8000289c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028a0:	6422                	ld	s0,8(sp)
    800028a2:	0141                	addi	sp,sp,16
    800028a4:	8082                	ret

00000000800028a6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028a6:	1141                	addi	sp,sp,-16
    800028a8:	e406                	sd	ra,8(sp)
    800028aa:	e022                	sd	s0,0(sp)
    800028ac:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ae:	fffff097          	auipc	ra,0xfffff
    800028b2:	0e4080e7          	jalr	228(ra) # 80001992 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028ba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028bc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028c0:	00004617          	auipc	a2,0x4
    800028c4:	74060613          	addi	a2,a2,1856 # 80007000 <_trampoline>
    800028c8:	00004697          	auipc	a3,0x4
    800028cc:	73868693          	addi	a3,a3,1848 # 80007000 <_trampoline>
    800028d0:	8e91                	sub	a3,a3,a2
    800028d2:	040007b7          	lui	a5,0x4000
    800028d6:	17fd                	addi	a5,a5,-1
    800028d8:	07b2                	slli	a5,a5,0xc
    800028da:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028dc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028e0:	7938                	ld	a4,112(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028e2:	180026f3          	csrr	a3,satp
    800028e6:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028e8:	7938                	ld	a4,112(a0)
    800028ea:	6d34                	ld	a3,88(a0)
    800028ec:	6585                	lui	a1,0x1
    800028ee:	96ae                	add	a3,a3,a1
    800028f0:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028f2:	7938                	ld	a4,112(a0)
    800028f4:	00000697          	auipc	a3,0x0
    800028f8:	1b268693          	addi	a3,a3,434 # 80002aa6 <usertrap>
    800028fc:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028fe:	7938                	ld	a4,112(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002900:	8692                	mv	a3,tp
    80002902:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002904:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002908:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000290c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002910:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002914:	7938                	ld	a4,112(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002916:	6f18                	ld	a4,24(a4)
    80002918:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000291c:	752c                	ld	a1,104(a0)
    8000291e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002920:	00004717          	auipc	a4,0x4
    80002924:	77070713          	addi	a4,a4,1904 # 80007090 <userret>
    80002928:	8f11                	sub	a4,a4,a2
    8000292a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000292c:	577d                	li	a4,-1
    8000292e:	177e                	slli	a4,a4,0x3f
    80002930:	8dd9                	or	a1,a1,a4
    80002932:	02000537          	lui	a0,0x2000
    80002936:	157d                	addi	a0,a0,-1
    80002938:	0536                	slli	a0,a0,0xd
    8000293a:	9782                	jalr	a5
}
    8000293c:	60a2                	ld	ra,8(sp)
    8000293e:	6402                	ld	s0,0(sp)
    80002940:	0141                	addi	sp,sp,16
    80002942:	8082                	ret

0000000080002944 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002944:	7139                	addi	sp,sp,-64
    80002946:	fc06                	sd	ra,56(sp)
    80002948:	f822                	sd	s0,48(sp)
    8000294a:	f426                	sd	s1,40(sp)
    8000294c:	f04a                	sd	s2,32(sp)
    8000294e:	ec4e                	sd	s3,24(sp)
    80002950:	e852                	sd	s4,16(sp)
    80002952:	e456                	sd	s5,8(sp)
    80002954:	0080                	addi	s0,sp,64
  acquire(&tickslock);
    80002956:	00015517          	auipc	a0,0x15
    8000295a:	d7a50513          	addi	a0,a0,-646 # 800176d0 <tickslock>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	264080e7          	jalr	612(ra) # 80000bc2 <acquire>
  ticks++;
    80002966:	00006717          	auipc	a4,0x6
    8000296a:	6ca70713          	addi	a4,a4,1738 # 80009030 <ticks>
    8000296e:	431c                	lw	a5,0(a4)
    80002970:	2785                	addiw	a5,a5,1
    80002972:	c31c                	sw	a5,0(a4)
  //start add UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE
  struct proc *p;
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	e98080e7          	jalr	-360(ra) # 8000180c <getProc>
    8000297c:	84aa                	mv	s1,a0
    8000297e:	6919                	lui	s2,0x6
    acquire(&p->lock);

    enum procstate state = p->state;
    switch (state)
    80002980:	4a8d                	li	s5,3
    80002982:	4a11                	li	s4,4
    80002984:	4989                	li	s3,2
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    80002986:	a819                	j	8000299c <clockintr+0x58>
        break;
      case SLEEPING:
        p->stime += 1;
        break;
      case RUNNABLE:
        p->retime += 1;
    80002988:	40fc                	lw	a5,68(s1)
    8000298a:	2785                	addiw	a5,a5,1
    8000298c:	c0fc                	sw	a5,68(s1)
      case ZOMBIE:   
        break; 
      default:
        break;
    }
    release(&p->lock);
    8000298e:	8526                	mv	a0,s1
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	2e6080e7          	jalr	742(ra) # 80000c76 <release>
  for(p = getProc(); p < &getProc()[NPROC]; p++){
    80002998:	18048493          	addi	s1,s1,384
    8000299c:	fffff097          	auipc	ra,0xfffff
    800029a0:	e70080e7          	jalr	-400(ra) # 8000180c <getProc>
    800029a4:	954a                	add	a0,a0,s2
    800029a6:	02a4f663          	bgeu	s1,a0,800029d2 <clockintr+0x8e>
    acquire(&p->lock);
    800029aa:	8526                	mv	a0,s1
    800029ac:	ffffe097          	auipc	ra,0xffffe
    800029b0:	216080e7          	jalr	534(ra) # 80000bc2 <acquire>
    enum procstate state = p->state;
    800029b4:	4c9c                	lw	a5,24(s1)
    switch (state)
    800029b6:	fd5789e3          	beq	a5,s5,80002988 <clockintr+0x44>
    800029ba:	01478863          	beq	a5,s4,800029ca <clockintr+0x86>
    800029be:	fd3798e3          	bne	a5,s3,8000298e <clockintr+0x4a>
        p->stime += 1;
    800029c2:	40bc                	lw	a5,64(s1)
    800029c4:	2785                	addiw	a5,a5,1
    800029c6:	c0bc                	sw	a5,64(s1)
        break;
    800029c8:	b7d9                	j	8000298e <clockintr+0x4a>
        p->runtime += 1;
    800029ca:	44bc                	lw	a5,72(s1)
    800029cc:	2785                	addiw	a5,a5,1
    800029ce:	c4bc                	sw	a5,72(s1)
        break;
    800029d0:	bf7d                	j	8000298e <clockintr+0x4a>
  }
  // end add
  wakeup(&ticks);
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	65e50513          	addi	a0,a0,1630 # 80009030 <ticks>
    800029da:	00000097          	auipc	ra,0x0
    800029de:	874080e7          	jalr	-1932(ra) # 8000224e <wakeup>
  release(&tickslock);
    800029e2:	00015517          	auipc	a0,0x15
    800029e6:	cee50513          	addi	a0,a0,-786 # 800176d0 <tickslock>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	28c080e7          	jalr	652(ra) # 80000c76 <release>
}
    800029f2:	70e2                	ld	ra,56(sp)
    800029f4:	7442                	ld	s0,48(sp)
    800029f6:	74a2                	ld	s1,40(sp)
    800029f8:	7902                	ld	s2,32(sp)
    800029fa:	69e2                	ld	s3,24(sp)
    800029fc:	6a42                	ld	s4,16(sp)
    800029fe:	6aa2                	ld	s5,8(sp)
    80002a00:	6121                	addi	sp,sp,64
    80002a02:	8082                	ret

0000000080002a04 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a04:	1101                	addi	sp,sp,-32
    80002a06:	ec06                	sd	ra,24(sp)
    80002a08:	e822                	sd	s0,16(sp)
    80002a0a:	e426                	sd	s1,8(sp)
    80002a0c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a0e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a12:	00074d63          	bltz	a4,80002a2c <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a16:	57fd                	li	a5,-1
    80002a18:	17fe                	slli	a5,a5,0x3f
    80002a1a:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a1c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a1e:	06f70363          	beq	a4,a5,80002a84 <devintr+0x80>
  }
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6105                	addi	sp,sp,32
    80002a2a:	8082                	ret
     (scause & 0xff) == 9){
    80002a2c:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a30:	46a5                	li	a3,9
    80002a32:	fed792e3          	bne	a5,a3,80002a16 <devintr+0x12>
    int irq = plic_claim();
    80002a36:	00003097          	auipc	ra,0x3
    80002a3a:	5a2080e7          	jalr	1442(ra) # 80005fd8 <plic_claim>
    80002a3e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a40:	47a9                	li	a5,10
    80002a42:	02f50763          	beq	a0,a5,80002a70 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a46:	4785                	li	a5,1
    80002a48:	02f50963          	beq	a0,a5,80002a7a <devintr+0x76>
    return 1;
    80002a4c:	4505                	li	a0,1
    } else if(irq){
    80002a4e:	d8f1                	beqz	s1,80002a22 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a50:	85a6                	mv	a1,s1
    80002a52:	00006517          	auipc	a0,0x6
    80002a56:	94650513          	addi	a0,a0,-1722 # 80008398 <states.0+0x38>
    80002a5a:	ffffe097          	auipc	ra,0xffffe
    80002a5e:	b1a080e7          	jalr	-1254(ra) # 80000574 <printf>
      plic_complete(irq);
    80002a62:	8526                	mv	a0,s1
    80002a64:	00003097          	auipc	ra,0x3
    80002a68:	598080e7          	jalr	1432(ra) # 80005ffc <plic_complete>
    return 1;
    80002a6c:	4505                	li	a0,1
    80002a6e:	bf55                	j	80002a22 <devintr+0x1e>
      uartintr();
    80002a70:	ffffe097          	auipc	ra,0xffffe
    80002a74:	f16080e7          	jalr	-234(ra) # 80000986 <uartintr>
    80002a78:	b7ed                	j	80002a62 <devintr+0x5e>
      virtio_disk_intr();
    80002a7a:	00004097          	auipc	ra,0x4
    80002a7e:	a14080e7          	jalr	-1516(ra) # 8000648e <virtio_disk_intr>
    80002a82:	b7c5                	j	80002a62 <devintr+0x5e>
    if(cpuid() == 0){
    80002a84:	fffff097          	auipc	ra,0xfffff
    80002a88:	ee2080e7          	jalr	-286(ra) # 80001966 <cpuid>
    80002a8c:	c901                	beqz	a0,80002a9c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a8e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a92:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a94:	14479073          	csrw	sip,a5
    return 2;
    80002a98:	4509                	li	a0,2
    80002a9a:	b761                	j	80002a22 <devintr+0x1e>
      clockintr();
    80002a9c:	00000097          	auipc	ra,0x0
    80002aa0:	ea8080e7          	jalr	-344(ra) # 80002944 <clockintr>
    80002aa4:	b7ed                	j	80002a8e <devintr+0x8a>

0000000080002aa6 <usertrap>:
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	e04a                	sd	s2,0(sp)
    80002ab0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ab6:	1007f793          	andi	a5,a5,256
    80002aba:	e3ad                	bnez	a5,80002b1c <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002abc:	00003797          	auipc	a5,0x3
    80002ac0:	41478793          	addi	a5,a5,1044 # 80005ed0 <kernelvec>
    80002ac4:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	eca080e7          	jalr	-310(ra) # 80001992 <myproc>
    80002ad0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ad2:	793c                	ld	a5,112(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ad4:	14102773          	csrr	a4,sepc
    80002ad8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ada:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ade:	47a1                	li	a5,8
    80002ae0:	04f71c63          	bne	a4,a5,80002b38 <usertrap+0x92>
    if(p->killed)
    80002ae4:	551c                	lw	a5,40(a0)
    80002ae6:	e3b9                	bnez	a5,80002b2c <usertrap+0x86>
    p->trapframe->epc += 4;
    80002ae8:	78b8                	ld	a4,112(s1)
    80002aea:	6f1c                	ld	a5,24(a4)
    80002aec:	0791                	addi	a5,a5,4
    80002aee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002af4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002af8:	10079073          	csrw	sstatus,a5
    syscall();
    80002afc:	00000097          	auipc	ra,0x0
    80002b00:	2e0080e7          	jalr	736(ra) # 80002ddc <syscall>
  if(p->killed)
    80002b04:	549c                	lw	a5,40(s1)
    80002b06:	ebc1                	bnez	a5,80002b96 <usertrap+0xf0>
  usertrapret();
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	d9e080e7          	jalr	-610(ra) # 800028a6 <usertrapret>
}
    80002b10:	60e2                	ld	ra,24(sp)
    80002b12:	6442                	ld	s0,16(sp)
    80002b14:	64a2                	ld	s1,8(sp)
    80002b16:	6902                	ld	s2,0(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret
    panic("usertrap: not from user mode");
    80002b1c:	00006517          	auipc	a0,0x6
    80002b20:	89c50513          	addi	a0,a0,-1892 # 800083b8 <states.0+0x58>
    80002b24:	ffffe097          	auipc	ra,0xffffe
    80002b28:	a06080e7          	jalr	-1530(ra) # 8000052a <panic>
      exit(-1);
    80002b2c:	557d                	li	a0,-1
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	7f0080e7          	jalr	2032(ra) # 8000231e <exit>
    80002b36:	bf4d                	j	80002ae8 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	ecc080e7          	jalr	-308(ra) # 80002a04 <devintr>
    80002b40:	892a                	mv	s2,a0
    80002b42:	c501                	beqz	a0,80002b4a <usertrap+0xa4>
  if(p->killed)
    80002b44:	549c                	lw	a5,40(s1)
    80002b46:	c3a1                	beqz	a5,80002b86 <usertrap+0xe0>
    80002b48:	a815                	j	80002b7c <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b4a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b4e:	5890                	lw	a2,48(s1)
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	88850513          	addi	a0,a0,-1912 # 800083d8 <states.0+0x78>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	a1c080e7          	jalr	-1508(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b60:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b64:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b68:	00006517          	auipc	a0,0x6
    80002b6c:	8a050513          	addi	a0,a0,-1888 # 80008408 <states.0+0xa8>
    80002b70:	ffffe097          	auipc	ra,0xffffe
    80002b74:	a04080e7          	jalr	-1532(ra) # 80000574 <printf>
    p->killed = 1;
    80002b78:	4785                	li	a5,1
    80002b7a:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002b7c:	557d                	li	a0,-1
    80002b7e:	fffff097          	auipc	ra,0xfffff
    80002b82:	7a0080e7          	jalr	1952(ra) # 8000231e <exit>
  if(which_dev == 2)
    80002b86:	4789                	li	a5,2
    80002b88:	f8f910e3          	bne	s2,a5,80002b08 <usertrap+0x62>
    yield();
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	4fa080e7          	jalr	1274(ra) # 80002086 <yield>
    80002b94:	bf95                	j	80002b08 <usertrap+0x62>
  int which_dev = 0;
    80002b96:	4901                	li	s2,0
    80002b98:	b7d5                	j	80002b7c <usertrap+0xd6>

0000000080002b9a <kerneltrap>:
{
    80002b9a:	7179                	addi	sp,sp,-48
    80002b9c:	f406                	sd	ra,40(sp)
    80002b9e:	f022                	sd	s0,32(sp)
    80002ba0:	ec26                	sd	s1,24(sp)
    80002ba2:	e84a                	sd	s2,16(sp)
    80002ba4:	e44e                	sd	s3,8(sp)
    80002ba6:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ba8:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bac:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb0:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bb4:	1004f793          	andi	a5,s1,256
    80002bb8:	cb85                	beqz	a5,80002be8 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bba:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bbe:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bc0:	ef85                	bnez	a5,80002bf8 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bc2:	00000097          	auipc	ra,0x0
    80002bc6:	e42080e7          	jalr	-446(ra) # 80002a04 <devintr>
    80002bca:	cd1d                	beqz	a0,80002c08 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bcc:	4789                	li	a5,2
    80002bce:	06f50a63          	beq	a0,a5,80002c42 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bd2:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10049073          	csrw	sstatus,s1
}
    80002bda:	70a2                	ld	ra,40(sp)
    80002bdc:	7402                	ld	s0,32(sp)
    80002bde:	64e2                	ld	s1,24(sp)
    80002be0:	6942                	ld	s2,16(sp)
    80002be2:	69a2                	ld	s3,8(sp)
    80002be4:	6145                	addi	sp,sp,48
    80002be6:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002be8:	00006517          	auipc	a0,0x6
    80002bec:	84050513          	addi	a0,a0,-1984 # 80008428 <states.0+0xc8>
    80002bf0:	ffffe097          	auipc	ra,0xffffe
    80002bf4:	93a080e7          	jalr	-1734(ra) # 8000052a <panic>
    panic("kerneltrap: interrupts enabled");
    80002bf8:	00006517          	auipc	a0,0x6
    80002bfc:	85850513          	addi	a0,a0,-1960 # 80008450 <states.0+0xf0>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	92a080e7          	jalr	-1750(ra) # 8000052a <panic>
    printf("scause %p\n", scause);
    80002c08:	85ce                	mv	a1,s3
    80002c0a:	00006517          	auipc	a0,0x6
    80002c0e:	86650513          	addi	a0,a0,-1946 # 80008470 <states.0+0x110>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	962080e7          	jalr	-1694(ra) # 80000574 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c1a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c1e:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c22:	00006517          	auipc	a0,0x6
    80002c26:	85e50513          	addi	a0,a0,-1954 # 80008480 <states.0+0x120>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	94a080e7          	jalr	-1718(ra) # 80000574 <printf>
    panic("kerneltrap");
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	86650513          	addi	a0,a0,-1946 # 80008498 <states.0+0x138>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	8f0080e7          	jalr	-1808(ra) # 8000052a <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	d50080e7          	jalr	-688(ra) # 80001992 <myproc>
    80002c4a:	d541                	beqz	a0,80002bd2 <kerneltrap+0x38>
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	d46080e7          	jalr	-698(ra) # 80001992 <myproc>
    80002c54:	4d18                	lw	a4,24(a0)
    80002c56:	4791                	li	a5,4
    80002c58:	f6f71de3          	bne	a4,a5,80002bd2 <kerneltrap+0x38>
    yield();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	42a080e7          	jalr	1066(ra) # 80002086 <yield>
    80002c64:	b7bd                	j	80002bd2 <kerneltrap+0x38>

0000000080002c66 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c66:	1101                	addi	sp,sp,-32
    80002c68:	ec06                	sd	ra,24(sp)
    80002c6a:	e822                	sd	s0,16(sp)
    80002c6c:	e426                	sd	s1,8(sp)
    80002c6e:	1000                	addi	s0,sp,32
    80002c70:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	d20080e7          	jalr	-736(ra) # 80001992 <myproc>
  switch (n)
    80002c7a:	4795                	li	a5,5
    80002c7c:	0497e163          	bltu	a5,s1,80002cbe <argraw+0x58>
    80002c80:	048a                	slli	s1,s1,0x2
    80002c82:	00006717          	auipc	a4,0x6
    80002c86:	9de70713          	addi	a4,a4,-1570 # 80008660 <states.0+0x300>
    80002c8a:	94ba                	add	s1,s1,a4
    80002c8c:	409c                	lw	a5,0(s1)
    80002c8e:	97ba                	add	a5,a5,a4
    80002c90:	8782                	jr	a5
  {
  case 0:
    return p->trapframe->a0;
    80002c92:	793c                	ld	a5,112(a0)
    80002c94:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret
    return p->trapframe->a1;
    80002ca0:	793c                	ld	a5,112(a0)
    80002ca2:	7fa8                	ld	a0,120(a5)
    80002ca4:	bfcd                	j	80002c96 <argraw+0x30>
    return p->trapframe->a2;
    80002ca6:	793c                	ld	a5,112(a0)
    80002ca8:	63c8                	ld	a0,128(a5)
    80002caa:	b7f5                	j	80002c96 <argraw+0x30>
    return p->trapframe->a3;
    80002cac:	793c                	ld	a5,112(a0)
    80002cae:	67c8                	ld	a0,136(a5)
    80002cb0:	b7dd                	j	80002c96 <argraw+0x30>
    return p->trapframe->a4;
    80002cb2:	793c                	ld	a5,112(a0)
    80002cb4:	6bc8                	ld	a0,144(a5)
    80002cb6:	b7c5                	j	80002c96 <argraw+0x30>
    return p->trapframe->a5;
    80002cb8:	793c                	ld	a5,112(a0)
    80002cba:	6fc8                	ld	a0,152(a5)
    80002cbc:	bfe9                	j	80002c96 <argraw+0x30>
  panic("argraw");
    80002cbe:	00005517          	auipc	a0,0x5
    80002cc2:	7ea50513          	addi	a0,a0,2026 # 800084a8 <states.0+0x148>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	864080e7          	jalr	-1948(ra) # 8000052a <panic>

0000000080002cce <fetchaddr>:
{
    80002cce:	1101                	addi	sp,sp,-32
    80002cd0:	ec06                	sd	ra,24(sp)
    80002cd2:	e822                	sd	s0,16(sp)
    80002cd4:	e426                	sd	s1,8(sp)
    80002cd6:	e04a                	sd	s2,0(sp)
    80002cd8:	1000                	addi	s0,sp,32
    80002cda:	84aa                	mv	s1,a0
    80002cdc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	cb4080e7          	jalr	-844(ra) # 80001992 <myproc>
  if (addr >= p->sz || addr + sizeof(uint64) > p->sz)
    80002ce6:	713c                	ld	a5,96(a0)
    80002ce8:	02f4f863          	bgeu	s1,a5,80002d18 <fetchaddr+0x4a>
    80002cec:	00848713          	addi	a4,s1,8
    80002cf0:	02e7e663          	bltu	a5,a4,80002d1c <fetchaddr+0x4e>
  if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002cf4:	46a1                	li	a3,8
    80002cf6:	8626                	mv	a2,s1
    80002cf8:	85ca                	mv	a1,s2
    80002cfa:	7528                	ld	a0,104(a0)
    80002cfc:	fffff097          	auipc	ra,0xfffff
    80002d00:	9ce080e7          	jalr	-1586(ra) # 800016ca <copyin>
    80002d04:	00a03533          	snez	a0,a0
    80002d08:	40a00533          	neg	a0,a0
}
    80002d0c:	60e2                	ld	ra,24(sp)
    80002d0e:	6442                	ld	s0,16(sp)
    80002d10:	64a2                	ld	s1,8(sp)
    80002d12:	6902                	ld	s2,0(sp)
    80002d14:	6105                	addi	sp,sp,32
    80002d16:	8082                	ret
    return -1;
    80002d18:	557d                	li	a0,-1
    80002d1a:	bfcd                	j	80002d0c <fetchaddr+0x3e>
    80002d1c:	557d                	li	a0,-1
    80002d1e:	b7fd                	j	80002d0c <fetchaddr+0x3e>

0000000080002d20 <fetchstr>:
{
    80002d20:	7179                	addi	sp,sp,-48
    80002d22:	f406                	sd	ra,40(sp)
    80002d24:	f022                	sd	s0,32(sp)
    80002d26:	ec26                	sd	s1,24(sp)
    80002d28:	e84a                	sd	s2,16(sp)
    80002d2a:	e44e                	sd	s3,8(sp)
    80002d2c:	1800                	addi	s0,sp,48
    80002d2e:	892a                	mv	s2,a0
    80002d30:	84ae                	mv	s1,a1
    80002d32:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d34:	fffff097          	auipc	ra,0xfffff
    80002d38:	c5e080e7          	jalr	-930(ra) # 80001992 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d3c:	86ce                	mv	a3,s3
    80002d3e:	864a                	mv	a2,s2
    80002d40:	85a6                	mv	a1,s1
    80002d42:	7528                	ld	a0,104(a0)
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	a14080e7          	jalr	-1516(ra) # 80001758 <copyinstr>
  if (err < 0)
    80002d4c:	00054763          	bltz	a0,80002d5a <fetchstr+0x3a>
  return strlen(buf);
    80002d50:	8526                	mv	a0,s1
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	0f0080e7          	jalr	240(ra) # 80000e42 <strlen>
}
    80002d5a:	70a2                	ld	ra,40(sp)
    80002d5c:	7402                	ld	s0,32(sp)
    80002d5e:	64e2                	ld	s1,24(sp)
    80002d60:	6942                	ld	s2,16(sp)
    80002d62:	69a2                	ld	s3,8(sp)
    80002d64:	6145                	addi	sp,sp,48
    80002d66:	8082                	ret

0000000080002d68 <argint>:

// Fetch the nth 32-bit system call argument.
int argint(int n, int *ip)
{
    80002d68:	1101                	addi	sp,sp,-32
    80002d6a:	ec06                	sd	ra,24(sp)
    80002d6c:	e822                	sd	s0,16(sp)
    80002d6e:	e426                	sd	s1,8(sp)
    80002d70:	1000                	addi	s0,sp,32
    80002d72:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d74:	00000097          	auipc	ra,0x0
    80002d78:	ef2080e7          	jalr	-270(ra) # 80002c66 <argraw>
    80002d7c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002d7e:	4501                	li	a0,0
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	64a2                	ld	s1,8(sp)
    80002d86:	6105                	addi	sp,sp,32
    80002d88:	8082                	ret

0000000080002d8a <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int argaddr(int n, uint64 *ip)
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	e426                	sd	s1,8(sp)
    80002d92:	1000                	addi	s0,sp,32
    80002d94:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	ed0080e7          	jalr	-304(ra) # 80002c66 <argraw>
    80002d9e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002da0:	4501                	li	a0,0
    80002da2:	60e2                	ld	ra,24(sp)
    80002da4:	6442                	ld	s0,16(sp)
    80002da6:	64a2                	ld	s1,8(sp)
    80002da8:	6105                	addi	sp,sp,32
    80002daa:	8082                	ret

0000000080002dac <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	e04a                	sd	s2,0(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84ae                	mv	s1,a1
    80002dba:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	eaa080e7          	jalr	-342(ra) # 80002c66 <argraw>
  uint64 addr;
  if (argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dc4:	864a                	mv	a2,s2
    80002dc6:	85a6                	mv	a1,s1
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	f58080e7          	jalr	-168(ra) # 80002d20 <fetchstr>
}
    80002dd0:	60e2                	ld	ra,24(sp)
    80002dd2:	6442                	ld	s0,16(sp)
    80002dd4:	64a2                	ld	s1,8(sp)
    80002dd6:	6902                	ld	s2,0(sp)
    80002dd8:	6105                	addi	sp,sp,32
    80002dda:	8082                	ret

0000000080002ddc <syscall>:
    [SYS_close] "sys_close",
    [SYS_trace] "sys_trace",
    [SYS_wait_stat] "sys_wait_stat",
};
void syscall(void)
{
    80002ddc:	7139                	addi	sp,sp,-64
    80002dde:	fc06                	sd	ra,56(sp)
    80002de0:	f822                	sd	s0,48(sp)
    80002de2:	f426                	sd	s1,40(sp)
    80002de4:	f04a                	sd	s2,32(sp)
    80002de6:	ec4e                	sd	s3,24(sp)
    80002de8:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002dea:	fffff097          	auipc	ra,0xfffff
    80002dee:	ba8080e7          	jalr	-1112(ra) # 80001992 <myproc>
    80002df2:	84aa                	mv	s1,a0
  int firstArg;
  num = p->trapframe->a7;
    80002df4:	07053903          	ld	s2,112(a0)
    80002df8:	0a893783          	ld	a5,168(s2) # 60a8 <_entry-0x7fff9f58>
    80002dfc:	0007899b          	sext.w	s3,a5
  if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80002e00:	37fd                	addiw	a5,a5,-1
    80002e02:	4759                	li	a4,22
    80002e04:	0cf76563          	bltu	a4,a5,80002ece <syscall+0xf2>
    80002e08:	00399713          	slli	a4,s3,0x3
    80002e0c:	00006797          	auipc	a5,0x6
    80002e10:	86c78793          	addi	a5,a5,-1940 # 80008678 <syscalls>
    80002e14:	97ba                	add	a5,a5,a4
    80002e16:	639c                	ld	a5,0(a5)
    80002e18:	cbdd                	beqz	a5,80002ece <syscall+0xf2>
  {
    p->trapframe->a0 = syscalls[num]();
    80002e1a:	9782                	jalr	a5
    80002e1c:	06a93823          	sd	a0,112(s2)
    //start messing with code
    if ((p->traceMask & (1 << num)))
    80002e20:	58dc                	lw	a5,52(s1)
    80002e22:	4137d7bb          	sraw	a5,a5,s3
    80002e26:	8b85                	andi	a5,a5,1
    80002e28:	c3f1                	beqz	a5,80002eec <syscall+0x110>
    {
      printf("%d: syscall %s ", p->pid, syscalls_str[num]);
    80002e2a:	00399713          	slli	a4,s3,0x3
    80002e2e:	00006797          	auipc	a5,0x6
    80002e32:	84a78793          	addi	a5,a5,-1974 # 80008678 <syscalls>
    80002e36:	97ba                	add	a5,a5,a4
    80002e38:	63f0                	ld	a2,192(a5)
    80002e3a:	588c                	lw	a1,48(s1)
    80002e3c:	00005517          	auipc	a0,0x5
    80002e40:	67450513          	addi	a0,a0,1652 # 800084b0 <states.0+0x150>
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	730080e7          	jalr	1840(ra) # 80000574 <printf>
      if (num == SYS_fork)
    80002e4c:	4785                	li	a5,1
    80002e4e:	02f98363          	beq	s3,a5,80002e74 <syscall+0x98>
      {
        printf("NULL ");
      }
      if (num == SYS_kill)
    80002e52:	4799                	li	a5,6
    80002e54:	02f98963          	beq	s3,a5,80002e86 <syscall+0xaa>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      if (num == SYS_sbrk)
    80002e58:	47b1                	li	a5,12
    80002e5a:	04f98863          	beq	s3,a5,80002eaa <syscall+0xce>
      {
        argint(0, &firstArg);

        printf("%d ", firstArg);
      }
      printf("-> %d\n", p->trapframe->a0);
    80002e5e:	78bc                	ld	a5,112(s1)
    80002e60:	7bac                	ld	a1,112(a5)
    80002e62:	00005517          	auipc	a0,0x5
    80002e66:	66e50513          	addi	a0,a0,1646 # 800084d0 <states.0+0x170>
    80002e6a:	ffffd097          	auipc	ra,0xffffd
    80002e6e:	70a080e7          	jalr	1802(ra) # 80000574 <printf>
    80002e72:	a8ad                	j	80002eec <syscall+0x110>
        printf("NULL ");
    80002e74:	00005517          	auipc	a0,0x5
    80002e78:	64c50513          	addi	a0,a0,1612 # 800084c0 <states.0+0x160>
    80002e7c:	ffffd097          	auipc	ra,0xffffd
    80002e80:	6f8080e7          	jalr	1784(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002e84:	bfe9                	j	80002e5e <syscall+0x82>
        argint(0, &firstArg);
    80002e86:	fcc40593          	addi	a1,s0,-52
    80002e8a:	4501                	li	a0,0
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	edc080e7          	jalr	-292(ra) # 80002d68 <argint>
        printf("%d ", firstArg);
    80002e94:	fcc42583          	lw	a1,-52(s0)
    80002e98:	00005517          	auipc	a0,0x5
    80002e9c:	63050513          	addi	a0,a0,1584 # 800084c8 <states.0+0x168>
    80002ea0:	ffffd097          	auipc	ra,0xffffd
    80002ea4:	6d4080e7          	jalr	1748(ra) # 80000574 <printf>
      if (num == SYS_sbrk)
    80002ea8:	bf5d                	j	80002e5e <syscall+0x82>
        argint(0, &firstArg);
    80002eaa:	fcc40593          	addi	a1,s0,-52
    80002eae:	4501                	li	a0,0
    80002eb0:	00000097          	auipc	ra,0x0
    80002eb4:	eb8080e7          	jalr	-328(ra) # 80002d68 <argint>
        printf("%d ", firstArg);
    80002eb8:	fcc42583          	lw	a1,-52(s0)
    80002ebc:	00005517          	auipc	a0,0x5
    80002ec0:	60c50513          	addi	a0,a0,1548 # 800084c8 <states.0+0x168>
    80002ec4:	ffffd097          	auipc	ra,0xffffd
    80002ec8:	6b0080e7          	jalr	1712(ra) # 80000574 <printf>
    80002ecc:	bf49                	j	80002e5e <syscall+0x82>
    }
    //end messing with code
  }
  else
  {
    printf("%d %s: unknown sys call %d\n",
    80002ece:	86ce                	mv	a3,s3
    80002ed0:	17048613          	addi	a2,s1,368
    80002ed4:	588c                	lw	a1,48(s1)
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	60250513          	addi	a0,a0,1538 # 800084d8 <states.0+0x178>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	696080e7          	jalr	1686(ra) # 80000574 <printf>
           p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ee6:	78bc                	ld	a5,112(s1)
    80002ee8:	577d                	li	a4,-1
    80002eea:	fbb8                	sd	a4,112(a5)
  }
}
    80002eec:	70e2                	ld	ra,56(sp)
    80002eee:	7442                	ld	s0,48(sp)
    80002ef0:	74a2                	ld	s1,40(sp)
    80002ef2:	7902                	ld	s2,32(sp)
    80002ef4:	69e2                	ld	s3,24(sp)
    80002ef6:	6121                	addi	sp,sp,64
    80002ef8:	8082                	ret

0000000080002efa <sys_wait_stat>:
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_wait_stat(void){
    80002efa:	1101                	addi	sp,sp,-32
    80002efc:	ec06                	sd	ra,24(sp)
    80002efe:	e822                	sd	s0,16(sp)
    80002f00:	1000                	addi	s0,sp,32
  int* status ;
  struct perf* performance;
  argint(0, (int*)&status);
    80002f02:	fe840593          	addi	a1,s0,-24
    80002f06:	4501                	li	a0,0
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	e60080e7          	jalr	-416(ra) # 80002d68 <argint>
  argint(1, (int*)&performance);
    80002f10:	fe040593          	addi	a1,s0,-32
    80002f14:	4505                	li	a0,1
    80002f16:	00000097          	auipc	ra,0x0
    80002f1a:	e52080e7          	jalr	-430(ra) # 80002d68 <argint>
  return wait_stat((int*)status, performance);
    80002f1e:	fe043583          	ld	a1,-32(s0)
    80002f22:	fe843503          	ld	a0,-24(s0)
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	56c080e7          	jalr	1388(ra) # 80002492 <wait_stat>
}
    80002f2e:	60e2                	ld	ra,24(sp)
    80002f30:	6442                	ld	s0,16(sp)
    80002f32:	6105                	addi	sp,sp,32
    80002f34:	8082                	ret

0000000080002f36 <sys_trace>:

uint64
sys_trace(void)
{
    80002f36:	1101                	addi	sp,sp,-32
    80002f38:	ec06                	sd	ra,24(sp)
    80002f3a:	e822                	sd	s0,16(sp)
    80002f3c:	1000                	addi	s0,sp,32
  int mask;
  int pid;
  argint(0, &mask);
    80002f3e:	fec40593          	addi	a1,s0,-20
    80002f42:	4501                	li	a0,0
    80002f44:	00000097          	auipc	ra,0x0
    80002f48:	e24080e7          	jalr	-476(ra) # 80002d68 <argint>
  if(argint(1, &pid) < 0)
    80002f4c:	fe840593          	addi	a1,s0,-24
    80002f50:	4505                	li	a0,1
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	e16080e7          	jalr	-490(ra) # 80002d68 <argint>
    80002f5a:	87aa                	mv	a5,a0
    return -1;
    80002f5c:	557d                	li	a0,-1
  if(argint(1, &pid) < 0)
    80002f5e:	0007ca63          	bltz	a5,80002f72 <sys_trace+0x3c>
  return trace(mask, pid);
    80002f62:	fe842583          	lw	a1,-24(s0)
    80002f66:	fec42503          	lw	a0,-20(s0)
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	6cc080e7          	jalr	1740(ra) # 80002636 <trace>
}
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	6105                	addi	sp,sp,32
    80002f78:	8082                	ret

0000000080002f7a <sys_exit>:

uint64
sys_exit(void)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f82:	fec40593          	addi	a1,s0,-20
    80002f86:	4501                	li	a0,0
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	de0080e7          	jalr	-544(ra) # 80002d68 <argint>
    return -1;
    80002f90:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f92:	00054963          	bltz	a0,80002fa4 <sys_exit+0x2a>
  exit(n);
    80002f96:	fec42503          	lw	a0,-20(s0)
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	384080e7          	jalr	900(ra) # 8000231e <exit>
  return 0;  // not reached
    80002fa2:	4781                	li	a5,0
}
    80002fa4:	853e                	mv	a0,a5
    80002fa6:	60e2                	ld	ra,24(sp)
    80002fa8:	6442                	ld	s0,16(sp)
    80002faa:	6105                	addi	sp,sp,32
    80002fac:	8082                	ret

0000000080002fae <sys_getpid>:

uint64
sys_getpid(void)
{
    80002fae:	1141                	addi	sp,sp,-16
    80002fb0:	e406                	sd	ra,8(sp)
    80002fb2:	e022                	sd	s0,0(sp)
    80002fb4:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	9dc080e7          	jalr	-1572(ra) # 80001992 <myproc>
}
    80002fbe:	5908                	lw	a0,48(a0)
    80002fc0:	60a2                	ld	ra,8(sp)
    80002fc2:	6402                	ld	s0,0(sp)
    80002fc4:	0141                	addi	sp,sp,16
    80002fc6:	8082                	ret

0000000080002fc8 <sys_fork>:

uint64
sys_fork(void)
{
    80002fc8:	1141                	addi	sp,sp,-16
    80002fca:	e406                	sd	ra,8(sp)
    80002fcc:	e022                	sd	s0,0(sp)
    80002fce:	0800                	addi	s0,sp,16
  return fork();
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	dd2080e7          	jalr	-558(ra) # 80001da2 <fork>
}
    80002fd8:	60a2                	ld	ra,8(sp)
    80002fda:	6402                	ld	s0,0(sp)
    80002fdc:	0141                	addi	sp,sp,16
    80002fde:	8082                	ret

0000000080002fe0 <sys_wait>:

uint64
sys_wait(void)
{
    80002fe0:	1101                	addi	sp,sp,-32
    80002fe2:	ec06                	sd	ra,24(sp)
    80002fe4:	e822                	sd	s0,16(sp)
    80002fe6:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fe8:	fe840593          	addi	a1,s0,-24
    80002fec:	4501                	li	a0,0
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	d9c080e7          	jalr	-612(ra) # 80002d8a <argaddr>
    80002ff6:	87aa                	mv	a5,a0
    return -1;
    80002ff8:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ffa:	0007c863          	bltz	a5,8000300a <sys_wait+0x2a>
  return wait(p);
    80002ffe:	fe843503          	ld	a0,-24(s0)
    80003002:	fffff097          	auipc	ra,0xfffff
    80003006:	124080e7          	jalr	292(ra) # 80002126 <wait>
}
    8000300a:	60e2                	ld	ra,24(sp)
    8000300c:	6442                	ld	s0,16(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret

0000000080003012 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003012:	7179                	addi	sp,sp,-48
    80003014:	f406                	sd	ra,40(sp)
    80003016:	f022                	sd	s0,32(sp)
    80003018:	ec26                	sd	s1,24(sp)
    8000301a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    8000301c:	fdc40593          	addi	a1,s0,-36
    80003020:	4501                	li	a0,0
    80003022:	00000097          	auipc	ra,0x0
    80003026:	d46080e7          	jalr	-698(ra) # 80002d68 <argint>
    return -1;
    8000302a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    8000302c:	00054f63          	bltz	a0,8000304a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80003030:	fffff097          	auipc	ra,0xfffff
    80003034:	962080e7          	jalr	-1694(ra) # 80001992 <myproc>
    80003038:	5124                	lw	s1,96(a0)
  if(growproc(n) < 0)
    8000303a:	fdc42503          	lw	a0,-36(s0)
    8000303e:	fffff097          	auipc	ra,0xfffff
    80003042:	cf0080e7          	jalr	-784(ra) # 80001d2e <growproc>
    80003046:	00054863          	bltz	a0,80003056 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    8000304a:	8526                	mv	a0,s1
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6145                	addi	sp,sp,48
    80003054:	8082                	ret
    return -1;
    80003056:	54fd                	li	s1,-1
    80003058:	bfcd                	j	8000304a <sys_sbrk+0x38>

000000008000305a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000305a:	7139                	addi	sp,sp,-64
    8000305c:	fc06                	sd	ra,56(sp)
    8000305e:	f822                	sd	s0,48(sp)
    80003060:	f426                	sd	s1,40(sp)
    80003062:	f04a                	sd	s2,32(sp)
    80003064:	ec4e                	sd	s3,24(sp)
    80003066:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003068:	fcc40593          	addi	a1,s0,-52
    8000306c:	4501                	li	a0,0
    8000306e:	00000097          	auipc	ra,0x0
    80003072:	cfa080e7          	jalr	-774(ra) # 80002d68 <argint>
    return -1;
    80003076:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003078:	06054563          	bltz	a0,800030e2 <sys_sleep+0x88>
  acquire(&tickslock);
    8000307c:	00014517          	auipc	a0,0x14
    80003080:	65450513          	addi	a0,a0,1620 # 800176d0 <tickslock>
    80003084:	ffffe097          	auipc	ra,0xffffe
    80003088:	b3e080e7          	jalr	-1218(ra) # 80000bc2 <acquire>
  ticks0 = ticks;
    8000308c:	00006917          	auipc	s2,0x6
    80003090:	fa492903          	lw	s2,-92(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003094:	fcc42783          	lw	a5,-52(s0)
    80003098:	cf85                	beqz	a5,800030d0 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000309a:	00014997          	auipc	s3,0x14
    8000309e:	63698993          	addi	s3,s3,1590 # 800176d0 <tickslock>
    800030a2:	00006497          	auipc	s1,0x6
    800030a6:	f8e48493          	addi	s1,s1,-114 # 80009030 <ticks>
    if(myproc()->killed){
    800030aa:	fffff097          	auipc	ra,0xfffff
    800030ae:	8e8080e7          	jalr	-1816(ra) # 80001992 <myproc>
    800030b2:	551c                	lw	a5,40(a0)
    800030b4:	ef9d                	bnez	a5,800030f2 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    800030b6:	85ce                	mv	a1,s3
    800030b8:	8526                	mv	a0,s1
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	008080e7          	jalr	8(ra) # 800020c2 <sleep>
  while(ticks - ticks0 < n){
    800030c2:	409c                	lw	a5,0(s1)
    800030c4:	412787bb          	subw	a5,a5,s2
    800030c8:	fcc42703          	lw	a4,-52(s0)
    800030cc:	fce7efe3          	bltu	a5,a4,800030aa <sys_sleep+0x50>
  }
  release(&tickslock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	60050513          	addi	a0,a0,1536 # 800176d0 <tickslock>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	b9e080e7          	jalr	-1122(ra) # 80000c76 <release>
  return 0;
    800030e0:	4781                	li	a5,0
}
    800030e2:	853e                	mv	a0,a5
    800030e4:	70e2                	ld	ra,56(sp)
    800030e6:	7442                	ld	s0,48(sp)
    800030e8:	74a2                	ld	s1,40(sp)
    800030ea:	7902                	ld	s2,32(sp)
    800030ec:	69e2                	ld	s3,24(sp)
    800030ee:	6121                	addi	sp,sp,64
    800030f0:	8082                	ret
      release(&tickslock);
    800030f2:	00014517          	auipc	a0,0x14
    800030f6:	5de50513          	addi	a0,a0,1502 # 800176d0 <tickslock>
    800030fa:	ffffe097          	auipc	ra,0xffffe
    800030fe:	b7c080e7          	jalr	-1156(ra) # 80000c76 <release>
      return -1;
    80003102:	57fd                	li	a5,-1
    80003104:	bff9                	j	800030e2 <sys_sleep+0x88>

0000000080003106 <sys_kill>:

uint64
sys_kill(void)
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000310e:	fec40593          	addi	a1,s0,-20
    80003112:	4501                	li	a0,0
    80003114:	00000097          	auipc	ra,0x0
    80003118:	c54080e7          	jalr	-940(ra) # 80002d68 <argint>
    8000311c:	87aa                	mv	a5,a0
    return -1;
    8000311e:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003120:	0007c863          	bltz	a5,80003130 <sys_kill+0x2a>
  return kill(pid);
    80003124:	fec42503          	lw	a0,-20(s0)
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	2f8080e7          	jalr	760(ra) # 80002420 <kill>
}
    80003130:	60e2                	ld	ra,24(sp)
    80003132:	6442                	ld	s0,16(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret

0000000080003138 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003138:	1101                	addi	sp,sp,-32
    8000313a:	ec06                	sd	ra,24(sp)
    8000313c:	e822                	sd	s0,16(sp)
    8000313e:	e426                	sd	s1,8(sp)
    80003140:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	58e50513          	addi	a0,a0,1422 # 800176d0 <tickslock>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	a78080e7          	jalr	-1416(ra) # 80000bc2 <acquire>
  xticks = ticks;
    80003152:	00006497          	auipc	s1,0x6
    80003156:	ede4a483          	lw	s1,-290(s1) # 80009030 <ticks>
  release(&tickslock);
    8000315a:	00014517          	auipc	a0,0x14
    8000315e:	57650513          	addi	a0,a0,1398 # 800176d0 <tickslock>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	b14080e7          	jalr	-1260(ra) # 80000c76 <release>
  return xticks;
}
    8000316a:	02049513          	slli	a0,s1,0x20
    8000316e:	9101                	srli	a0,a0,0x20
    80003170:	60e2                	ld	ra,24(sp)
    80003172:	6442                	ld	s0,16(sp)
    80003174:	64a2                	ld	s1,8(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret

000000008000317a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000317a:	7179                	addi	sp,sp,-48
    8000317c:	f406                	sd	ra,40(sp)
    8000317e:	f022                	sd	s0,32(sp)
    80003180:	ec26                	sd	s1,24(sp)
    80003182:	e84a                	sd	s2,16(sp)
    80003184:	e44e                	sd	s3,8(sp)
    80003186:	e052                	sd	s4,0(sp)
    80003188:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000318a:	00005597          	auipc	a1,0x5
    8000318e:	66e58593          	addi	a1,a1,1646 # 800087f8 <syscalls_str+0xc0>
    80003192:	00014517          	auipc	a0,0x14
    80003196:	55650513          	addi	a0,a0,1366 # 800176e8 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	998080e7          	jalr	-1640(ra) # 80000b32 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800031a2:	0001c797          	auipc	a5,0x1c
    800031a6:	54678793          	addi	a5,a5,1350 # 8001f6e8 <bcache+0x8000>
    800031aa:	0001c717          	auipc	a4,0x1c
    800031ae:	7a670713          	addi	a4,a4,1958 # 8001f950 <bcache+0x8268>
    800031b2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800031b6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ba:	00014497          	auipc	s1,0x14
    800031be:	54648493          	addi	s1,s1,1350 # 80017700 <bcache+0x18>
    b->next = bcache.head.next;
    800031c2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800031c4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800031c6:	00005a17          	auipc	s4,0x5
    800031ca:	63aa0a13          	addi	s4,s4,1594 # 80008800 <syscalls_str+0xc8>
    b->next = bcache.head.next;
    800031ce:	2b893783          	ld	a5,696(s2)
    800031d2:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800031d4:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031d8:	85d2                	mv	a1,s4
    800031da:	01048513          	addi	a0,s1,16
    800031de:	00001097          	auipc	ra,0x1
    800031e2:	4c2080e7          	jalr	1218(ra) # 800046a0 <initsleeplock>
    bcache.head.next->prev = b;
    800031e6:	2b893783          	ld	a5,696(s2)
    800031ea:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031ec:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031f0:	45848493          	addi	s1,s1,1112
    800031f4:	fd349de3          	bne	s1,s3,800031ce <binit+0x54>
  }
}
    800031f8:	70a2                	ld	ra,40(sp)
    800031fa:	7402                	ld	s0,32(sp)
    800031fc:	64e2                	ld	s1,24(sp)
    800031fe:	6942                	ld	s2,16(sp)
    80003200:	69a2                	ld	s3,8(sp)
    80003202:	6a02                	ld	s4,0(sp)
    80003204:	6145                	addi	sp,sp,48
    80003206:	8082                	ret

0000000080003208 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003208:	7179                	addi	sp,sp,-48
    8000320a:	f406                	sd	ra,40(sp)
    8000320c:	f022                	sd	s0,32(sp)
    8000320e:	ec26                	sd	s1,24(sp)
    80003210:	e84a                	sd	s2,16(sp)
    80003212:	e44e                	sd	s3,8(sp)
    80003214:	1800                	addi	s0,sp,48
    80003216:	892a                	mv	s2,a0
    80003218:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000321a:	00014517          	auipc	a0,0x14
    8000321e:	4ce50513          	addi	a0,a0,1230 # 800176e8 <bcache>
    80003222:	ffffe097          	auipc	ra,0xffffe
    80003226:	9a0080e7          	jalr	-1632(ra) # 80000bc2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000322a:	0001c497          	auipc	s1,0x1c
    8000322e:	7764b483          	ld	s1,1910(s1) # 8001f9a0 <bcache+0x82b8>
    80003232:	0001c797          	auipc	a5,0x1c
    80003236:	71e78793          	addi	a5,a5,1822 # 8001f950 <bcache+0x8268>
    8000323a:	02f48f63          	beq	s1,a5,80003278 <bread+0x70>
    8000323e:	873e                	mv	a4,a5
    80003240:	a021                	j	80003248 <bread+0x40>
    80003242:	68a4                	ld	s1,80(s1)
    80003244:	02e48a63          	beq	s1,a4,80003278 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003248:	449c                	lw	a5,8(s1)
    8000324a:	ff279ce3          	bne	a5,s2,80003242 <bread+0x3a>
    8000324e:	44dc                	lw	a5,12(s1)
    80003250:	ff3799e3          	bne	a5,s3,80003242 <bread+0x3a>
      b->refcnt++;
    80003254:	40bc                	lw	a5,64(s1)
    80003256:	2785                	addiw	a5,a5,1
    80003258:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000325a:	00014517          	auipc	a0,0x14
    8000325e:	48e50513          	addi	a0,a0,1166 # 800176e8 <bcache>
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a14080e7          	jalr	-1516(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    8000326a:	01048513          	addi	a0,s1,16
    8000326e:	00001097          	auipc	ra,0x1
    80003272:	46c080e7          	jalr	1132(ra) # 800046da <acquiresleep>
      return b;
    80003276:	a8b9                	j	800032d4 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003278:	0001c497          	auipc	s1,0x1c
    8000327c:	7204b483          	ld	s1,1824(s1) # 8001f998 <bcache+0x82b0>
    80003280:	0001c797          	auipc	a5,0x1c
    80003284:	6d078793          	addi	a5,a5,1744 # 8001f950 <bcache+0x8268>
    80003288:	00f48863          	beq	s1,a5,80003298 <bread+0x90>
    8000328c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000328e:	40bc                	lw	a5,64(s1)
    80003290:	cf81                	beqz	a5,800032a8 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003292:	64a4                	ld	s1,72(s1)
    80003294:	fee49de3          	bne	s1,a4,8000328e <bread+0x86>
  panic("bget: no buffers");
    80003298:	00005517          	auipc	a0,0x5
    8000329c:	57050513          	addi	a0,a0,1392 # 80008808 <syscalls_str+0xd0>
    800032a0:	ffffd097          	auipc	ra,0xffffd
    800032a4:	28a080e7          	jalr	650(ra) # 8000052a <panic>
      b->dev = dev;
    800032a8:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800032ac:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800032b0:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800032b4:	4785                	li	a5,1
    800032b6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032b8:	00014517          	auipc	a0,0x14
    800032bc:	43050513          	addi	a0,a0,1072 # 800176e8 <bcache>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	9b6080e7          	jalr	-1610(ra) # 80000c76 <release>
      acquiresleep(&b->lock);
    800032c8:	01048513          	addi	a0,s1,16
    800032cc:	00001097          	auipc	ra,0x1
    800032d0:	40e080e7          	jalr	1038(ra) # 800046da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800032d4:	409c                	lw	a5,0(s1)
    800032d6:	cb89                	beqz	a5,800032e8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032d8:	8526                	mv	a0,s1
    800032da:	70a2                	ld	ra,40(sp)
    800032dc:	7402                	ld	s0,32(sp)
    800032de:	64e2                	ld	s1,24(sp)
    800032e0:	6942                	ld	s2,16(sp)
    800032e2:	69a2                	ld	s3,8(sp)
    800032e4:	6145                	addi	sp,sp,48
    800032e6:	8082                	ret
    virtio_disk_rw(b, 0);
    800032e8:	4581                	li	a1,0
    800032ea:	8526                	mv	a0,s1
    800032ec:	00003097          	auipc	ra,0x3
    800032f0:	f1a080e7          	jalr	-230(ra) # 80006206 <virtio_disk_rw>
    b->valid = 1;
    800032f4:	4785                	li	a5,1
    800032f6:	c09c                	sw	a5,0(s1)
  return b;
    800032f8:	b7c5                	j	800032d8 <bread+0xd0>

00000000800032fa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032fa:	1101                	addi	sp,sp,-32
    800032fc:	ec06                	sd	ra,24(sp)
    800032fe:	e822                	sd	s0,16(sp)
    80003300:	e426                	sd	s1,8(sp)
    80003302:	1000                	addi	s0,sp,32
    80003304:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003306:	0541                	addi	a0,a0,16
    80003308:	00001097          	auipc	ra,0x1
    8000330c:	46c080e7          	jalr	1132(ra) # 80004774 <holdingsleep>
    80003310:	cd01                	beqz	a0,80003328 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003312:	4585                	li	a1,1
    80003314:	8526                	mv	a0,s1
    80003316:	00003097          	auipc	ra,0x3
    8000331a:	ef0080e7          	jalr	-272(ra) # 80006206 <virtio_disk_rw>
}
    8000331e:	60e2                	ld	ra,24(sp)
    80003320:	6442                	ld	s0,16(sp)
    80003322:	64a2                	ld	s1,8(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret
    panic("bwrite");
    80003328:	00005517          	auipc	a0,0x5
    8000332c:	4f850513          	addi	a0,a0,1272 # 80008820 <syscalls_str+0xe8>
    80003330:	ffffd097          	auipc	ra,0xffffd
    80003334:	1fa080e7          	jalr	506(ra) # 8000052a <panic>

0000000080003338 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003338:	1101                	addi	sp,sp,-32
    8000333a:	ec06                	sd	ra,24(sp)
    8000333c:	e822                	sd	s0,16(sp)
    8000333e:	e426                	sd	s1,8(sp)
    80003340:	e04a                	sd	s2,0(sp)
    80003342:	1000                	addi	s0,sp,32
    80003344:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003346:	01050913          	addi	s2,a0,16
    8000334a:	854a                	mv	a0,s2
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	428080e7          	jalr	1064(ra) # 80004774 <holdingsleep>
    80003354:	c92d                	beqz	a0,800033c6 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003356:	854a                	mv	a0,s2
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	3d8080e7          	jalr	984(ra) # 80004730 <releasesleep>

  acquire(&bcache.lock);
    80003360:	00014517          	auipc	a0,0x14
    80003364:	38850513          	addi	a0,a0,904 # 800176e8 <bcache>
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	85a080e7          	jalr	-1958(ra) # 80000bc2 <acquire>
  b->refcnt--;
    80003370:	40bc                	lw	a5,64(s1)
    80003372:	37fd                	addiw	a5,a5,-1
    80003374:	0007871b          	sext.w	a4,a5
    80003378:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000337a:	eb05                	bnez	a4,800033aa <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000337c:	68bc                	ld	a5,80(s1)
    8000337e:	64b8                	ld	a4,72(s1)
    80003380:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003382:	64bc                	ld	a5,72(s1)
    80003384:	68b8                	ld	a4,80(s1)
    80003386:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003388:	0001c797          	auipc	a5,0x1c
    8000338c:	36078793          	addi	a5,a5,864 # 8001f6e8 <bcache+0x8000>
    80003390:	2b87b703          	ld	a4,696(a5)
    80003394:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003396:	0001c717          	auipc	a4,0x1c
    8000339a:	5ba70713          	addi	a4,a4,1466 # 8001f950 <bcache+0x8268>
    8000339e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800033a0:	2b87b703          	ld	a4,696(a5)
    800033a4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800033a6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800033aa:	00014517          	auipc	a0,0x14
    800033ae:	33e50513          	addi	a0,a0,830 # 800176e8 <bcache>
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	8c4080e7          	jalr	-1852(ra) # 80000c76 <release>
}
    800033ba:	60e2                	ld	ra,24(sp)
    800033bc:	6442                	ld	s0,16(sp)
    800033be:	64a2                	ld	s1,8(sp)
    800033c0:	6902                	ld	s2,0(sp)
    800033c2:	6105                	addi	sp,sp,32
    800033c4:	8082                	ret
    panic("brelse");
    800033c6:	00005517          	auipc	a0,0x5
    800033ca:	46250513          	addi	a0,a0,1122 # 80008828 <syscalls_str+0xf0>
    800033ce:	ffffd097          	auipc	ra,0xffffd
    800033d2:	15c080e7          	jalr	348(ra) # 8000052a <panic>

00000000800033d6 <bpin>:

void
bpin(struct buf *b) {
    800033d6:	1101                	addi	sp,sp,-32
    800033d8:	ec06                	sd	ra,24(sp)
    800033da:	e822                	sd	s0,16(sp)
    800033dc:	e426                	sd	s1,8(sp)
    800033de:	1000                	addi	s0,sp,32
    800033e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033e2:	00014517          	auipc	a0,0x14
    800033e6:	30650513          	addi	a0,a0,774 # 800176e8 <bcache>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	7d8080e7          	jalr	2008(ra) # 80000bc2 <acquire>
  b->refcnt++;
    800033f2:	40bc                	lw	a5,64(s1)
    800033f4:	2785                	addiw	a5,a5,1
    800033f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033f8:	00014517          	auipc	a0,0x14
    800033fc:	2f050513          	addi	a0,a0,752 # 800176e8 <bcache>
    80003400:	ffffe097          	auipc	ra,0xffffe
    80003404:	876080e7          	jalr	-1930(ra) # 80000c76 <release>
}
    80003408:	60e2                	ld	ra,24(sp)
    8000340a:	6442                	ld	s0,16(sp)
    8000340c:	64a2                	ld	s1,8(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret

0000000080003412 <bunpin>:

void
bunpin(struct buf *b) {
    80003412:	1101                	addi	sp,sp,-32
    80003414:	ec06                	sd	ra,24(sp)
    80003416:	e822                	sd	s0,16(sp)
    80003418:	e426                	sd	s1,8(sp)
    8000341a:	1000                	addi	s0,sp,32
    8000341c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000341e:	00014517          	auipc	a0,0x14
    80003422:	2ca50513          	addi	a0,a0,714 # 800176e8 <bcache>
    80003426:	ffffd097          	auipc	ra,0xffffd
    8000342a:	79c080e7          	jalr	1948(ra) # 80000bc2 <acquire>
  b->refcnt--;
    8000342e:	40bc                	lw	a5,64(s1)
    80003430:	37fd                	addiw	a5,a5,-1
    80003432:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003434:	00014517          	auipc	a0,0x14
    80003438:	2b450513          	addi	a0,a0,692 # 800176e8 <bcache>
    8000343c:	ffffe097          	auipc	ra,0xffffe
    80003440:	83a080e7          	jalr	-1990(ra) # 80000c76 <release>
}
    80003444:	60e2                	ld	ra,24(sp)
    80003446:	6442                	ld	s0,16(sp)
    80003448:	64a2                	ld	s1,8(sp)
    8000344a:	6105                	addi	sp,sp,32
    8000344c:	8082                	ret

000000008000344e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000344e:	1101                	addi	sp,sp,-32
    80003450:	ec06                	sd	ra,24(sp)
    80003452:	e822                	sd	s0,16(sp)
    80003454:	e426                	sd	s1,8(sp)
    80003456:	e04a                	sd	s2,0(sp)
    80003458:	1000                	addi	s0,sp,32
    8000345a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000345c:	00d5d59b          	srliw	a1,a1,0xd
    80003460:	0001d797          	auipc	a5,0x1d
    80003464:	9647a783          	lw	a5,-1692(a5) # 8001fdc4 <sb+0x1c>
    80003468:	9dbd                	addw	a1,a1,a5
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	d9e080e7          	jalr	-610(ra) # 80003208 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003472:	0074f713          	andi	a4,s1,7
    80003476:	4785                	li	a5,1
    80003478:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000347c:	14ce                	slli	s1,s1,0x33
    8000347e:	90d9                	srli	s1,s1,0x36
    80003480:	00950733          	add	a4,a0,s1
    80003484:	05874703          	lbu	a4,88(a4)
    80003488:	00e7f6b3          	and	a3,a5,a4
    8000348c:	c69d                	beqz	a3,800034ba <bfree+0x6c>
    8000348e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003490:	94aa                	add	s1,s1,a0
    80003492:	fff7c793          	not	a5,a5
    80003496:	8ff9                	and	a5,a5,a4
    80003498:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000349c:	00001097          	auipc	ra,0x1
    800034a0:	11e080e7          	jalr	286(ra) # 800045ba <log_write>
  brelse(bp);
    800034a4:	854a                	mv	a0,s2
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	e92080e7          	jalr	-366(ra) # 80003338 <brelse>
}
    800034ae:	60e2                	ld	ra,24(sp)
    800034b0:	6442                	ld	s0,16(sp)
    800034b2:	64a2                	ld	s1,8(sp)
    800034b4:	6902                	ld	s2,0(sp)
    800034b6:	6105                	addi	sp,sp,32
    800034b8:	8082                	ret
    panic("freeing free block");
    800034ba:	00005517          	auipc	a0,0x5
    800034be:	37650513          	addi	a0,a0,886 # 80008830 <syscalls_str+0xf8>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	068080e7          	jalr	104(ra) # 8000052a <panic>

00000000800034ca <balloc>:
{
    800034ca:	711d                	addi	sp,sp,-96
    800034cc:	ec86                	sd	ra,88(sp)
    800034ce:	e8a2                	sd	s0,80(sp)
    800034d0:	e4a6                	sd	s1,72(sp)
    800034d2:	e0ca                	sd	s2,64(sp)
    800034d4:	fc4e                	sd	s3,56(sp)
    800034d6:	f852                	sd	s4,48(sp)
    800034d8:	f456                	sd	s5,40(sp)
    800034da:	f05a                	sd	s6,32(sp)
    800034dc:	ec5e                	sd	s7,24(sp)
    800034de:	e862                	sd	s8,16(sp)
    800034e0:	e466                	sd	s9,8(sp)
    800034e2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034e4:	0001d797          	auipc	a5,0x1d
    800034e8:	8c87a783          	lw	a5,-1848(a5) # 8001fdac <sb+0x4>
    800034ec:	cbd1                	beqz	a5,80003580 <balloc+0xb6>
    800034ee:	8baa                	mv	s7,a0
    800034f0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034f2:	0001db17          	auipc	s6,0x1d
    800034f6:	8b6b0b13          	addi	s6,s6,-1866 # 8001fda8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034fc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034fe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003500:	6c89                	lui	s9,0x2
    80003502:	a831                	j	8000351e <balloc+0x54>
    brelse(bp);
    80003504:	854a                	mv	a0,s2
    80003506:	00000097          	auipc	ra,0x0
    8000350a:	e32080e7          	jalr	-462(ra) # 80003338 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000350e:	015c87bb          	addw	a5,s9,s5
    80003512:	00078a9b          	sext.w	s5,a5
    80003516:	004b2703          	lw	a4,4(s6)
    8000351a:	06eaf363          	bgeu	s5,a4,80003580 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000351e:	41fad79b          	sraiw	a5,s5,0x1f
    80003522:	0137d79b          	srliw	a5,a5,0x13
    80003526:	015787bb          	addw	a5,a5,s5
    8000352a:	40d7d79b          	sraiw	a5,a5,0xd
    8000352e:	01cb2583          	lw	a1,28(s6)
    80003532:	9dbd                	addw	a1,a1,a5
    80003534:	855e                	mv	a0,s7
    80003536:	00000097          	auipc	ra,0x0
    8000353a:	cd2080e7          	jalr	-814(ra) # 80003208 <bread>
    8000353e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003540:	004b2503          	lw	a0,4(s6)
    80003544:	000a849b          	sext.w	s1,s5
    80003548:	8662                	mv	a2,s8
    8000354a:	faa4fde3          	bgeu	s1,a0,80003504 <balloc+0x3a>
      m = 1 << (bi % 8);
    8000354e:	41f6579b          	sraiw	a5,a2,0x1f
    80003552:	01d7d69b          	srliw	a3,a5,0x1d
    80003556:	00c6873b          	addw	a4,a3,a2
    8000355a:	00777793          	andi	a5,a4,7
    8000355e:	9f95                	subw	a5,a5,a3
    80003560:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003564:	4037571b          	sraiw	a4,a4,0x3
    80003568:	00e906b3          	add	a3,s2,a4
    8000356c:	0586c683          	lbu	a3,88(a3)
    80003570:	00d7f5b3          	and	a1,a5,a3
    80003574:	cd91                	beqz	a1,80003590 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003576:	2605                	addiw	a2,a2,1
    80003578:	2485                	addiw	s1,s1,1
    8000357a:	fd4618e3          	bne	a2,s4,8000354a <balloc+0x80>
    8000357e:	b759                	j	80003504 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003580:	00005517          	auipc	a0,0x5
    80003584:	2c850513          	addi	a0,a0,712 # 80008848 <syscalls_str+0x110>
    80003588:	ffffd097          	auipc	ra,0xffffd
    8000358c:	fa2080e7          	jalr	-94(ra) # 8000052a <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003590:	974a                	add	a4,a4,s2
    80003592:	8fd5                	or	a5,a5,a3
    80003594:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003598:	854a                	mv	a0,s2
    8000359a:	00001097          	auipc	ra,0x1
    8000359e:	020080e7          	jalr	32(ra) # 800045ba <log_write>
        brelse(bp);
    800035a2:	854a                	mv	a0,s2
    800035a4:	00000097          	auipc	ra,0x0
    800035a8:	d94080e7          	jalr	-620(ra) # 80003338 <brelse>
  bp = bread(dev, bno);
    800035ac:	85a6                	mv	a1,s1
    800035ae:	855e                	mv	a0,s7
    800035b0:	00000097          	auipc	ra,0x0
    800035b4:	c58080e7          	jalr	-936(ra) # 80003208 <bread>
    800035b8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035ba:	40000613          	li	a2,1024
    800035be:	4581                	li	a1,0
    800035c0:	05850513          	addi	a0,a0,88
    800035c4:	ffffd097          	auipc	ra,0xffffd
    800035c8:	6fa080e7          	jalr	1786(ra) # 80000cbe <memset>
  log_write(bp);
    800035cc:	854a                	mv	a0,s2
    800035ce:	00001097          	auipc	ra,0x1
    800035d2:	fec080e7          	jalr	-20(ra) # 800045ba <log_write>
  brelse(bp);
    800035d6:	854a                	mv	a0,s2
    800035d8:	00000097          	auipc	ra,0x0
    800035dc:	d60080e7          	jalr	-672(ra) # 80003338 <brelse>
}
    800035e0:	8526                	mv	a0,s1
    800035e2:	60e6                	ld	ra,88(sp)
    800035e4:	6446                	ld	s0,80(sp)
    800035e6:	64a6                	ld	s1,72(sp)
    800035e8:	6906                	ld	s2,64(sp)
    800035ea:	79e2                	ld	s3,56(sp)
    800035ec:	7a42                	ld	s4,48(sp)
    800035ee:	7aa2                	ld	s5,40(sp)
    800035f0:	7b02                	ld	s6,32(sp)
    800035f2:	6be2                	ld	s7,24(sp)
    800035f4:	6c42                	ld	s8,16(sp)
    800035f6:	6ca2                	ld	s9,8(sp)
    800035f8:	6125                	addi	sp,sp,96
    800035fa:	8082                	ret

00000000800035fc <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035fc:	7179                	addi	sp,sp,-48
    800035fe:	f406                	sd	ra,40(sp)
    80003600:	f022                	sd	s0,32(sp)
    80003602:	ec26                	sd	s1,24(sp)
    80003604:	e84a                	sd	s2,16(sp)
    80003606:	e44e                	sd	s3,8(sp)
    80003608:	e052                	sd	s4,0(sp)
    8000360a:	1800                	addi	s0,sp,48
    8000360c:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000360e:	47ad                	li	a5,11
    80003610:	04b7fe63          	bgeu	a5,a1,8000366c <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003614:	ff45849b          	addiw	s1,a1,-12
    80003618:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000361c:	0ff00793          	li	a5,255
    80003620:	0ae7e463          	bltu	a5,a4,800036c8 <bmap+0xcc>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003624:	08052583          	lw	a1,128(a0)
    80003628:	c5b5                	beqz	a1,80003694 <bmap+0x98>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000362a:	00092503          	lw	a0,0(s2)
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	bda080e7          	jalr	-1062(ra) # 80003208 <bread>
    80003636:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003638:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000363c:	02049713          	slli	a4,s1,0x20
    80003640:	01e75593          	srli	a1,a4,0x1e
    80003644:	00b784b3          	add	s1,a5,a1
    80003648:	0004a983          	lw	s3,0(s1)
    8000364c:	04098e63          	beqz	s3,800036a8 <bmap+0xac>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003650:	8552                	mv	a0,s4
    80003652:	00000097          	auipc	ra,0x0
    80003656:	ce6080e7          	jalr	-794(ra) # 80003338 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000365a:	854e                	mv	a0,s3
    8000365c:	70a2                	ld	ra,40(sp)
    8000365e:	7402                	ld	s0,32(sp)
    80003660:	64e2                	ld	s1,24(sp)
    80003662:	6942                	ld	s2,16(sp)
    80003664:	69a2                	ld	s3,8(sp)
    80003666:	6a02                	ld	s4,0(sp)
    80003668:	6145                	addi	sp,sp,48
    8000366a:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000366c:	02059793          	slli	a5,a1,0x20
    80003670:	01e7d593          	srli	a1,a5,0x1e
    80003674:	00b504b3          	add	s1,a0,a1
    80003678:	0504a983          	lw	s3,80(s1)
    8000367c:	fc099fe3          	bnez	s3,8000365a <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003680:	4108                	lw	a0,0(a0)
    80003682:	00000097          	auipc	ra,0x0
    80003686:	e48080e7          	jalr	-440(ra) # 800034ca <balloc>
    8000368a:	0005099b          	sext.w	s3,a0
    8000368e:	0534a823          	sw	s3,80(s1)
    80003692:	b7e1                	j	8000365a <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003694:	4108                	lw	a0,0(a0)
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	e34080e7          	jalr	-460(ra) # 800034ca <balloc>
    8000369e:	0005059b          	sext.w	a1,a0
    800036a2:	08b92023          	sw	a1,128(s2)
    800036a6:	b751                	j	8000362a <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800036a8:	00092503          	lw	a0,0(s2)
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	e1e080e7          	jalr	-482(ra) # 800034ca <balloc>
    800036b4:	0005099b          	sext.w	s3,a0
    800036b8:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800036bc:	8552                	mv	a0,s4
    800036be:	00001097          	auipc	ra,0x1
    800036c2:	efc080e7          	jalr	-260(ra) # 800045ba <log_write>
    800036c6:	b769                	j	80003650 <bmap+0x54>
  panic("bmap: out of range");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	19850513          	addi	a0,a0,408 # 80008860 <syscalls_str+0x128>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e5a080e7          	jalr	-422(ra) # 8000052a <panic>

00000000800036d8 <iget>:
{
    800036d8:	7179                	addi	sp,sp,-48
    800036da:	f406                	sd	ra,40(sp)
    800036dc:	f022                	sd	s0,32(sp)
    800036de:	ec26                	sd	s1,24(sp)
    800036e0:	e84a                	sd	s2,16(sp)
    800036e2:	e44e                	sd	s3,8(sp)
    800036e4:	e052                	sd	s4,0(sp)
    800036e6:	1800                	addi	s0,sp,48
    800036e8:	89aa                	mv	s3,a0
    800036ea:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036ec:	0001c517          	auipc	a0,0x1c
    800036f0:	6dc50513          	addi	a0,a0,1756 # 8001fdc8 <itable>
    800036f4:	ffffd097          	auipc	ra,0xffffd
    800036f8:	4ce080e7          	jalr	1230(ra) # 80000bc2 <acquire>
  empty = 0;
    800036fc:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036fe:	0001c497          	auipc	s1,0x1c
    80003702:	6e248493          	addi	s1,s1,1762 # 8001fde0 <itable+0x18>
    80003706:	0001e697          	auipc	a3,0x1e
    8000370a:	16a68693          	addi	a3,a3,362 # 80021870 <log>
    8000370e:	a039                	j	8000371c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003710:	02090b63          	beqz	s2,80003746 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003714:	08848493          	addi	s1,s1,136
    80003718:	02d48a63          	beq	s1,a3,8000374c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000371c:	449c                	lw	a5,8(s1)
    8000371e:	fef059e3          	blez	a5,80003710 <iget+0x38>
    80003722:	4098                	lw	a4,0(s1)
    80003724:	ff3716e3          	bne	a4,s3,80003710 <iget+0x38>
    80003728:	40d8                	lw	a4,4(s1)
    8000372a:	ff4713e3          	bne	a4,s4,80003710 <iget+0x38>
      ip->ref++;
    8000372e:	2785                	addiw	a5,a5,1
    80003730:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003732:	0001c517          	auipc	a0,0x1c
    80003736:	69650513          	addi	a0,a0,1686 # 8001fdc8 <itable>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	53c080e7          	jalr	1340(ra) # 80000c76 <release>
      return ip;
    80003742:	8926                	mv	s2,s1
    80003744:	a03d                	j	80003772 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003746:	f7f9                	bnez	a5,80003714 <iget+0x3c>
    80003748:	8926                	mv	s2,s1
    8000374a:	b7e9                	j	80003714 <iget+0x3c>
  if(empty == 0)
    8000374c:	02090c63          	beqz	s2,80003784 <iget+0xac>
  ip->dev = dev;
    80003750:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003754:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003758:	4785                	li	a5,1
    8000375a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000375e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003762:	0001c517          	auipc	a0,0x1c
    80003766:	66650513          	addi	a0,a0,1638 # 8001fdc8 <itable>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	50c080e7          	jalr	1292(ra) # 80000c76 <release>
}
    80003772:	854a                	mv	a0,s2
    80003774:	70a2                	ld	ra,40(sp)
    80003776:	7402                	ld	s0,32(sp)
    80003778:	64e2                	ld	s1,24(sp)
    8000377a:	6942                	ld	s2,16(sp)
    8000377c:	69a2                	ld	s3,8(sp)
    8000377e:	6a02                	ld	s4,0(sp)
    80003780:	6145                	addi	sp,sp,48
    80003782:	8082                	ret
    panic("iget: no inodes");
    80003784:	00005517          	auipc	a0,0x5
    80003788:	0f450513          	addi	a0,a0,244 # 80008878 <syscalls_str+0x140>
    8000378c:	ffffd097          	auipc	ra,0xffffd
    80003790:	d9e080e7          	jalr	-610(ra) # 8000052a <panic>

0000000080003794 <fsinit>:
fsinit(int dev) {
    80003794:	7179                	addi	sp,sp,-48
    80003796:	f406                	sd	ra,40(sp)
    80003798:	f022                	sd	s0,32(sp)
    8000379a:	ec26                	sd	s1,24(sp)
    8000379c:	e84a                	sd	s2,16(sp)
    8000379e:	e44e                	sd	s3,8(sp)
    800037a0:	1800                	addi	s0,sp,48
    800037a2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800037a4:	4585                	li	a1,1
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	a62080e7          	jalr	-1438(ra) # 80003208 <bread>
    800037ae:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800037b0:	0001c997          	auipc	s3,0x1c
    800037b4:	5f898993          	addi	s3,s3,1528 # 8001fda8 <sb>
    800037b8:	02000613          	li	a2,32
    800037bc:	05850593          	addi	a1,a0,88
    800037c0:	854e                	mv	a0,s3
    800037c2:	ffffd097          	auipc	ra,0xffffd
    800037c6:	558080e7          	jalr	1368(ra) # 80000d1a <memmove>
  brelse(bp);
    800037ca:	8526                	mv	a0,s1
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	b6c080e7          	jalr	-1172(ra) # 80003338 <brelse>
  if(sb.magic != FSMAGIC)
    800037d4:	0009a703          	lw	a4,0(s3)
    800037d8:	102037b7          	lui	a5,0x10203
    800037dc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037e0:	02f71263          	bne	a4,a5,80003804 <fsinit+0x70>
  initlog(dev, &sb);
    800037e4:	0001c597          	auipc	a1,0x1c
    800037e8:	5c458593          	addi	a1,a1,1476 # 8001fda8 <sb>
    800037ec:	854a                	mv	a0,s2
    800037ee:	00001097          	auipc	ra,0x1
    800037f2:	b4e080e7          	jalr	-1202(ra) # 8000433c <initlog>
}
    800037f6:	70a2                	ld	ra,40(sp)
    800037f8:	7402                	ld	s0,32(sp)
    800037fa:	64e2                	ld	s1,24(sp)
    800037fc:	6942                	ld	s2,16(sp)
    800037fe:	69a2                	ld	s3,8(sp)
    80003800:	6145                	addi	sp,sp,48
    80003802:	8082                	ret
    panic("invalid file system");
    80003804:	00005517          	auipc	a0,0x5
    80003808:	08450513          	addi	a0,a0,132 # 80008888 <syscalls_str+0x150>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	d1e080e7          	jalr	-738(ra) # 8000052a <panic>

0000000080003814 <iinit>:
{
    80003814:	7179                	addi	sp,sp,-48
    80003816:	f406                	sd	ra,40(sp)
    80003818:	f022                	sd	s0,32(sp)
    8000381a:	ec26                	sd	s1,24(sp)
    8000381c:	e84a                	sd	s2,16(sp)
    8000381e:	e44e                	sd	s3,8(sp)
    80003820:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003822:	00005597          	auipc	a1,0x5
    80003826:	07e58593          	addi	a1,a1,126 # 800088a0 <syscalls_str+0x168>
    8000382a:	0001c517          	auipc	a0,0x1c
    8000382e:	59e50513          	addi	a0,a0,1438 # 8001fdc8 <itable>
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	300080e7          	jalr	768(ra) # 80000b32 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000383a:	0001c497          	auipc	s1,0x1c
    8000383e:	5b648493          	addi	s1,s1,1462 # 8001fdf0 <itable+0x28>
    80003842:	0001e997          	auipc	s3,0x1e
    80003846:	03e98993          	addi	s3,s3,62 # 80021880 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000384a:	00005917          	auipc	s2,0x5
    8000384e:	05e90913          	addi	s2,s2,94 # 800088a8 <syscalls_str+0x170>
    80003852:	85ca                	mv	a1,s2
    80003854:	8526                	mv	a0,s1
    80003856:	00001097          	auipc	ra,0x1
    8000385a:	e4a080e7          	jalr	-438(ra) # 800046a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000385e:	08848493          	addi	s1,s1,136
    80003862:	ff3498e3          	bne	s1,s3,80003852 <iinit+0x3e>
}
    80003866:	70a2                	ld	ra,40(sp)
    80003868:	7402                	ld	s0,32(sp)
    8000386a:	64e2                	ld	s1,24(sp)
    8000386c:	6942                	ld	s2,16(sp)
    8000386e:	69a2                	ld	s3,8(sp)
    80003870:	6145                	addi	sp,sp,48
    80003872:	8082                	ret

0000000080003874 <ialloc>:
{
    80003874:	715d                	addi	sp,sp,-80
    80003876:	e486                	sd	ra,72(sp)
    80003878:	e0a2                	sd	s0,64(sp)
    8000387a:	fc26                	sd	s1,56(sp)
    8000387c:	f84a                	sd	s2,48(sp)
    8000387e:	f44e                	sd	s3,40(sp)
    80003880:	f052                	sd	s4,32(sp)
    80003882:	ec56                	sd	s5,24(sp)
    80003884:	e85a                	sd	s6,16(sp)
    80003886:	e45e                	sd	s7,8(sp)
    80003888:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000388a:	0001c717          	auipc	a4,0x1c
    8000388e:	52a72703          	lw	a4,1322(a4) # 8001fdb4 <sb+0xc>
    80003892:	4785                	li	a5,1
    80003894:	04e7fa63          	bgeu	a5,a4,800038e8 <ialloc+0x74>
    80003898:	8aaa                	mv	s5,a0
    8000389a:	8bae                	mv	s7,a1
    8000389c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000389e:	0001ca17          	auipc	s4,0x1c
    800038a2:	50aa0a13          	addi	s4,s4,1290 # 8001fda8 <sb>
    800038a6:	00048b1b          	sext.w	s6,s1
    800038aa:	0044d793          	srli	a5,s1,0x4
    800038ae:	018a2583          	lw	a1,24(s4)
    800038b2:	9dbd                	addw	a1,a1,a5
    800038b4:	8556                	mv	a0,s5
    800038b6:	00000097          	auipc	ra,0x0
    800038ba:	952080e7          	jalr	-1710(ra) # 80003208 <bread>
    800038be:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800038c0:	05850993          	addi	s3,a0,88
    800038c4:	00f4f793          	andi	a5,s1,15
    800038c8:	079a                	slli	a5,a5,0x6
    800038ca:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038cc:	00099783          	lh	a5,0(s3)
    800038d0:	c785                	beqz	a5,800038f8 <ialloc+0x84>
    brelse(bp);
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	a66080e7          	jalr	-1434(ra) # 80003338 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038da:	0485                	addi	s1,s1,1
    800038dc:	00ca2703          	lw	a4,12(s4)
    800038e0:	0004879b          	sext.w	a5,s1
    800038e4:	fce7e1e3          	bltu	a5,a4,800038a6 <ialloc+0x32>
  panic("ialloc: no inodes");
    800038e8:	00005517          	auipc	a0,0x5
    800038ec:	fc850513          	addi	a0,a0,-56 # 800088b0 <syscalls_str+0x178>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	c3a080e7          	jalr	-966(ra) # 8000052a <panic>
      memset(dip, 0, sizeof(*dip));
    800038f8:	04000613          	li	a2,64
    800038fc:	4581                	li	a1,0
    800038fe:	854e                	mv	a0,s3
    80003900:	ffffd097          	auipc	ra,0xffffd
    80003904:	3be080e7          	jalr	958(ra) # 80000cbe <memset>
      dip->type = type;
    80003908:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000390c:	854a                	mv	a0,s2
    8000390e:	00001097          	auipc	ra,0x1
    80003912:	cac080e7          	jalr	-852(ra) # 800045ba <log_write>
      brelse(bp);
    80003916:	854a                	mv	a0,s2
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	a20080e7          	jalr	-1504(ra) # 80003338 <brelse>
      return iget(dev, inum);
    80003920:	85da                	mv	a1,s6
    80003922:	8556                	mv	a0,s5
    80003924:	00000097          	auipc	ra,0x0
    80003928:	db4080e7          	jalr	-588(ra) # 800036d8 <iget>
}
    8000392c:	60a6                	ld	ra,72(sp)
    8000392e:	6406                	ld	s0,64(sp)
    80003930:	74e2                	ld	s1,56(sp)
    80003932:	7942                	ld	s2,48(sp)
    80003934:	79a2                	ld	s3,40(sp)
    80003936:	7a02                	ld	s4,32(sp)
    80003938:	6ae2                	ld	s5,24(sp)
    8000393a:	6b42                	ld	s6,16(sp)
    8000393c:	6ba2                	ld	s7,8(sp)
    8000393e:	6161                	addi	sp,sp,80
    80003940:	8082                	ret

0000000080003942 <iupdate>:
{
    80003942:	1101                	addi	sp,sp,-32
    80003944:	ec06                	sd	ra,24(sp)
    80003946:	e822                	sd	s0,16(sp)
    80003948:	e426                	sd	s1,8(sp)
    8000394a:	e04a                	sd	s2,0(sp)
    8000394c:	1000                	addi	s0,sp,32
    8000394e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003950:	415c                	lw	a5,4(a0)
    80003952:	0047d79b          	srliw	a5,a5,0x4
    80003956:	0001c597          	auipc	a1,0x1c
    8000395a:	46a5a583          	lw	a1,1130(a1) # 8001fdc0 <sb+0x18>
    8000395e:	9dbd                	addw	a1,a1,a5
    80003960:	4108                	lw	a0,0(a0)
    80003962:	00000097          	auipc	ra,0x0
    80003966:	8a6080e7          	jalr	-1882(ra) # 80003208 <bread>
    8000396a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000396c:	05850793          	addi	a5,a0,88
    80003970:	40c8                	lw	a0,4(s1)
    80003972:	893d                	andi	a0,a0,15
    80003974:	051a                	slli	a0,a0,0x6
    80003976:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003978:	04449703          	lh	a4,68(s1)
    8000397c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003980:	04649703          	lh	a4,70(s1)
    80003984:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003988:	04849703          	lh	a4,72(s1)
    8000398c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003990:	04a49703          	lh	a4,74(s1)
    80003994:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003998:	44f8                	lw	a4,76(s1)
    8000399a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000399c:	03400613          	li	a2,52
    800039a0:	05048593          	addi	a1,s1,80
    800039a4:	0531                	addi	a0,a0,12
    800039a6:	ffffd097          	auipc	ra,0xffffd
    800039aa:	374080e7          	jalr	884(ra) # 80000d1a <memmove>
  log_write(bp);
    800039ae:	854a                	mv	a0,s2
    800039b0:	00001097          	auipc	ra,0x1
    800039b4:	c0a080e7          	jalr	-1014(ra) # 800045ba <log_write>
  brelse(bp);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	97e080e7          	jalr	-1666(ra) # 80003338 <brelse>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6902                	ld	s2,0(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret

00000000800039ce <idup>:
{
    800039ce:	1101                	addi	sp,sp,-32
    800039d0:	ec06                	sd	ra,24(sp)
    800039d2:	e822                	sd	s0,16(sp)
    800039d4:	e426                	sd	s1,8(sp)
    800039d6:	1000                	addi	s0,sp,32
    800039d8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039da:	0001c517          	auipc	a0,0x1c
    800039de:	3ee50513          	addi	a0,a0,1006 # 8001fdc8 <itable>
    800039e2:	ffffd097          	auipc	ra,0xffffd
    800039e6:	1e0080e7          	jalr	480(ra) # 80000bc2 <acquire>
  ip->ref++;
    800039ea:	449c                	lw	a5,8(s1)
    800039ec:	2785                	addiw	a5,a5,1
    800039ee:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039f0:	0001c517          	auipc	a0,0x1c
    800039f4:	3d850513          	addi	a0,a0,984 # 8001fdc8 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	27e080e7          	jalr	638(ra) # 80000c76 <release>
}
    80003a00:	8526                	mv	a0,s1
    80003a02:	60e2                	ld	ra,24(sp)
    80003a04:	6442                	ld	s0,16(sp)
    80003a06:	64a2                	ld	s1,8(sp)
    80003a08:	6105                	addi	sp,sp,32
    80003a0a:	8082                	ret

0000000080003a0c <ilock>:
{
    80003a0c:	1101                	addi	sp,sp,-32
    80003a0e:	ec06                	sd	ra,24(sp)
    80003a10:	e822                	sd	s0,16(sp)
    80003a12:	e426                	sd	s1,8(sp)
    80003a14:	e04a                	sd	s2,0(sp)
    80003a16:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003a18:	c115                	beqz	a0,80003a3c <ilock+0x30>
    80003a1a:	84aa                	mv	s1,a0
    80003a1c:	451c                	lw	a5,8(a0)
    80003a1e:	00f05f63          	blez	a5,80003a3c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a22:	0541                	addi	a0,a0,16
    80003a24:	00001097          	auipc	ra,0x1
    80003a28:	cb6080e7          	jalr	-842(ra) # 800046da <acquiresleep>
  if(ip->valid == 0){
    80003a2c:	40bc                	lw	a5,64(s1)
    80003a2e:	cf99                	beqz	a5,80003a4c <ilock+0x40>
}
    80003a30:	60e2                	ld	ra,24(sp)
    80003a32:	6442                	ld	s0,16(sp)
    80003a34:	64a2                	ld	s1,8(sp)
    80003a36:	6902                	ld	s2,0(sp)
    80003a38:	6105                	addi	sp,sp,32
    80003a3a:	8082                	ret
    panic("ilock");
    80003a3c:	00005517          	auipc	a0,0x5
    80003a40:	e8c50513          	addi	a0,a0,-372 # 800088c8 <syscalls_str+0x190>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	ae6080e7          	jalr	-1306(ra) # 8000052a <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a4c:	40dc                	lw	a5,4(s1)
    80003a4e:	0047d79b          	srliw	a5,a5,0x4
    80003a52:	0001c597          	auipc	a1,0x1c
    80003a56:	36e5a583          	lw	a1,878(a1) # 8001fdc0 <sb+0x18>
    80003a5a:	9dbd                	addw	a1,a1,a5
    80003a5c:	4088                	lw	a0,0(s1)
    80003a5e:	fffff097          	auipc	ra,0xfffff
    80003a62:	7aa080e7          	jalr	1962(ra) # 80003208 <bread>
    80003a66:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a68:	05850593          	addi	a1,a0,88
    80003a6c:	40dc                	lw	a5,4(s1)
    80003a6e:	8bbd                	andi	a5,a5,15
    80003a70:	079a                	slli	a5,a5,0x6
    80003a72:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a74:	00059783          	lh	a5,0(a1)
    80003a78:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a7c:	00259783          	lh	a5,2(a1)
    80003a80:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a84:	00459783          	lh	a5,4(a1)
    80003a88:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a8c:	00659783          	lh	a5,6(a1)
    80003a90:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a94:	459c                	lw	a5,8(a1)
    80003a96:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a98:	03400613          	li	a2,52
    80003a9c:	05b1                	addi	a1,a1,12
    80003a9e:	05048513          	addi	a0,s1,80
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	278080e7          	jalr	632(ra) # 80000d1a <memmove>
    brelse(bp);
    80003aaa:	854a                	mv	a0,s2
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	88c080e7          	jalr	-1908(ra) # 80003338 <brelse>
    ip->valid = 1;
    80003ab4:	4785                	li	a5,1
    80003ab6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ab8:	04449783          	lh	a5,68(s1)
    80003abc:	fbb5                	bnez	a5,80003a30 <ilock+0x24>
      panic("ilock: no type");
    80003abe:	00005517          	auipc	a0,0x5
    80003ac2:	e1250513          	addi	a0,a0,-494 # 800088d0 <syscalls_str+0x198>
    80003ac6:	ffffd097          	auipc	ra,0xffffd
    80003aca:	a64080e7          	jalr	-1436(ra) # 8000052a <panic>

0000000080003ace <iunlock>:
{
    80003ace:	1101                	addi	sp,sp,-32
    80003ad0:	ec06                	sd	ra,24(sp)
    80003ad2:	e822                	sd	s0,16(sp)
    80003ad4:	e426                	sd	s1,8(sp)
    80003ad6:	e04a                	sd	s2,0(sp)
    80003ad8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ada:	c905                	beqz	a0,80003b0a <iunlock+0x3c>
    80003adc:	84aa                	mv	s1,a0
    80003ade:	01050913          	addi	s2,a0,16
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	c90080e7          	jalr	-880(ra) # 80004774 <holdingsleep>
    80003aec:	cd19                	beqz	a0,80003b0a <iunlock+0x3c>
    80003aee:	449c                	lw	a5,8(s1)
    80003af0:	00f05d63          	blez	a5,80003b0a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	c3a080e7          	jalr	-966(ra) # 80004730 <releasesleep>
}
    80003afe:	60e2                	ld	ra,24(sp)
    80003b00:	6442                	ld	s0,16(sp)
    80003b02:	64a2                	ld	s1,8(sp)
    80003b04:	6902                	ld	s2,0(sp)
    80003b06:	6105                	addi	sp,sp,32
    80003b08:	8082                	ret
    panic("iunlock");
    80003b0a:	00005517          	auipc	a0,0x5
    80003b0e:	dd650513          	addi	a0,a0,-554 # 800088e0 <syscalls_str+0x1a8>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	a18080e7          	jalr	-1512(ra) # 8000052a <panic>

0000000080003b1a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003b1a:	7179                	addi	sp,sp,-48
    80003b1c:	f406                	sd	ra,40(sp)
    80003b1e:	f022                	sd	s0,32(sp)
    80003b20:	ec26                	sd	s1,24(sp)
    80003b22:	e84a                	sd	s2,16(sp)
    80003b24:	e44e                	sd	s3,8(sp)
    80003b26:	e052                	sd	s4,0(sp)
    80003b28:	1800                	addi	s0,sp,48
    80003b2a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b2c:	05050493          	addi	s1,a0,80
    80003b30:	08050913          	addi	s2,a0,128
    80003b34:	a021                	j	80003b3c <itrunc+0x22>
    80003b36:	0491                	addi	s1,s1,4
    80003b38:	01248d63          	beq	s1,s2,80003b52 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b3c:	408c                	lw	a1,0(s1)
    80003b3e:	dde5                	beqz	a1,80003b36 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b40:	0009a503          	lw	a0,0(s3)
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	90a080e7          	jalr	-1782(ra) # 8000344e <bfree>
      ip->addrs[i] = 0;
    80003b4c:	0004a023          	sw	zero,0(s1)
    80003b50:	b7dd                	j	80003b36 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b52:	0809a583          	lw	a1,128(s3)
    80003b56:	e185                	bnez	a1,80003b76 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b58:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b5c:	854e                	mv	a0,s3
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	de4080e7          	jalr	-540(ra) # 80003942 <iupdate>
}
    80003b66:	70a2                	ld	ra,40(sp)
    80003b68:	7402                	ld	s0,32(sp)
    80003b6a:	64e2                	ld	s1,24(sp)
    80003b6c:	6942                	ld	s2,16(sp)
    80003b6e:	69a2                	ld	s3,8(sp)
    80003b70:	6a02                	ld	s4,0(sp)
    80003b72:	6145                	addi	sp,sp,48
    80003b74:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b76:	0009a503          	lw	a0,0(s3)
    80003b7a:	fffff097          	auipc	ra,0xfffff
    80003b7e:	68e080e7          	jalr	1678(ra) # 80003208 <bread>
    80003b82:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b84:	05850493          	addi	s1,a0,88
    80003b88:	45850913          	addi	s2,a0,1112
    80003b8c:	a021                	j	80003b94 <itrunc+0x7a>
    80003b8e:	0491                	addi	s1,s1,4
    80003b90:	01248b63          	beq	s1,s2,80003ba6 <itrunc+0x8c>
      if(a[j])
    80003b94:	408c                	lw	a1,0(s1)
    80003b96:	dde5                	beqz	a1,80003b8e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003b98:	0009a503          	lw	a0,0(s3)
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	8b2080e7          	jalr	-1870(ra) # 8000344e <bfree>
    80003ba4:	b7ed                	j	80003b8e <itrunc+0x74>
    brelse(bp);
    80003ba6:	8552                	mv	a0,s4
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	790080e7          	jalr	1936(ra) # 80003338 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003bb0:	0809a583          	lw	a1,128(s3)
    80003bb4:	0009a503          	lw	a0,0(s3)
    80003bb8:	00000097          	auipc	ra,0x0
    80003bbc:	896080e7          	jalr	-1898(ra) # 8000344e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003bc0:	0809a023          	sw	zero,128(s3)
    80003bc4:	bf51                	j	80003b58 <itrunc+0x3e>

0000000080003bc6 <iput>:
{
    80003bc6:	1101                	addi	sp,sp,-32
    80003bc8:	ec06                	sd	ra,24(sp)
    80003bca:	e822                	sd	s0,16(sp)
    80003bcc:	e426                	sd	s1,8(sp)
    80003bce:	e04a                	sd	s2,0(sp)
    80003bd0:	1000                	addi	s0,sp,32
    80003bd2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bd4:	0001c517          	auipc	a0,0x1c
    80003bd8:	1f450513          	addi	a0,a0,500 # 8001fdc8 <itable>
    80003bdc:	ffffd097          	auipc	ra,0xffffd
    80003be0:	fe6080e7          	jalr	-26(ra) # 80000bc2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003be4:	4498                	lw	a4,8(s1)
    80003be6:	4785                	li	a5,1
    80003be8:	02f70363          	beq	a4,a5,80003c0e <iput+0x48>
  ip->ref--;
    80003bec:	449c                	lw	a5,8(s1)
    80003bee:	37fd                	addiw	a5,a5,-1
    80003bf0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bf2:	0001c517          	auipc	a0,0x1c
    80003bf6:	1d650513          	addi	a0,a0,470 # 8001fdc8 <itable>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	07c080e7          	jalr	124(ra) # 80000c76 <release>
}
    80003c02:	60e2                	ld	ra,24(sp)
    80003c04:	6442                	ld	s0,16(sp)
    80003c06:	64a2                	ld	s1,8(sp)
    80003c08:	6902                	ld	s2,0(sp)
    80003c0a:	6105                	addi	sp,sp,32
    80003c0c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c0e:	40bc                	lw	a5,64(s1)
    80003c10:	dff1                	beqz	a5,80003bec <iput+0x26>
    80003c12:	04a49783          	lh	a5,74(s1)
    80003c16:	fbf9                	bnez	a5,80003bec <iput+0x26>
    acquiresleep(&ip->lock);
    80003c18:	01048913          	addi	s2,s1,16
    80003c1c:	854a                	mv	a0,s2
    80003c1e:	00001097          	auipc	ra,0x1
    80003c22:	abc080e7          	jalr	-1348(ra) # 800046da <acquiresleep>
    release(&itable.lock);
    80003c26:	0001c517          	auipc	a0,0x1c
    80003c2a:	1a250513          	addi	a0,a0,418 # 8001fdc8 <itable>
    80003c2e:	ffffd097          	auipc	ra,0xffffd
    80003c32:	048080e7          	jalr	72(ra) # 80000c76 <release>
    itrunc(ip);
    80003c36:	8526                	mv	a0,s1
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	ee2080e7          	jalr	-286(ra) # 80003b1a <itrunc>
    ip->type = 0;
    80003c40:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c44:	8526                	mv	a0,s1
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	cfc080e7          	jalr	-772(ra) # 80003942 <iupdate>
    ip->valid = 0;
    80003c4e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c52:	854a                	mv	a0,s2
    80003c54:	00001097          	auipc	ra,0x1
    80003c58:	adc080e7          	jalr	-1316(ra) # 80004730 <releasesleep>
    acquire(&itable.lock);
    80003c5c:	0001c517          	auipc	a0,0x1c
    80003c60:	16c50513          	addi	a0,a0,364 # 8001fdc8 <itable>
    80003c64:	ffffd097          	auipc	ra,0xffffd
    80003c68:	f5e080e7          	jalr	-162(ra) # 80000bc2 <acquire>
    80003c6c:	b741                	j	80003bec <iput+0x26>

0000000080003c6e <iunlockput>:
{
    80003c6e:	1101                	addi	sp,sp,-32
    80003c70:	ec06                	sd	ra,24(sp)
    80003c72:	e822                	sd	s0,16(sp)
    80003c74:	e426                	sd	s1,8(sp)
    80003c76:	1000                	addi	s0,sp,32
    80003c78:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c7a:	00000097          	auipc	ra,0x0
    80003c7e:	e54080e7          	jalr	-428(ra) # 80003ace <iunlock>
  iput(ip);
    80003c82:	8526                	mv	a0,s1
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	f42080e7          	jalr	-190(ra) # 80003bc6 <iput>
}
    80003c8c:	60e2                	ld	ra,24(sp)
    80003c8e:	6442                	ld	s0,16(sp)
    80003c90:	64a2                	ld	s1,8(sp)
    80003c92:	6105                	addi	sp,sp,32
    80003c94:	8082                	ret

0000000080003c96 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c96:	1141                	addi	sp,sp,-16
    80003c98:	e422                	sd	s0,8(sp)
    80003c9a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c9c:	411c                	lw	a5,0(a0)
    80003c9e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ca0:	415c                	lw	a5,4(a0)
    80003ca2:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003ca4:	04451783          	lh	a5,68(a0)
    80003ca8:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003cac:	04a51783          	lh	a5,74(a0)
    80003cb0:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003cb4:	04c56783          	lwu	a5,76(a0)
    80003cb8:	e99c                	sd	a5,16(a1)
}
    80003cba:	6422                	ld	s0,8(sp)
    80003cbc:	0141                	addi	sp,sp,16
    80003cbe:	8082                	ret

0000000080003cc0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cc0:	457c                	lw	a5,76(a0)
    80003cc2:	0ed7e963          	bltu	a5,a3,80003db4 <readi+0xf4>
{
    80003cc6:	7159                	addi	sp,sp,-112
    80003cc8:	f486                	sd	ra,104(sp)
    80003cca:	f0a2                	sd	s0,96(sp)
    80003ccc:	eca6                	sd	s1,88(sp)
    80003cce:	e8ca                	sd	s2,80(sp)
    80003cd0:	e4ce                	sd	s3,72(sp)
    80003cd2:	e0d2                	sd	s4,64(sp)
    80003cd4:	fc56                	sd	s5,56(sp)
    80003cd6:	f85a                	sd	s6,48(sp)
    80003cd8:	f45e                	sd	s7,40(sp)
    80003cda:	f062                	sd	s8,32(sp)
    80003cdc:	ec66                	sd	s9,24(sp)
    80003cde:	e86a                	sd	s10,16(sp)
    80003ce0:	e46e                	sd	s11,8(sp)
    80003ce2:	1880                	addi	s0,sp,112
    80003ce4:	8baa                	mv	s7,a0
    80003ce6:	8c2e                	mv	s8,a1
    80003ce8:	8ab2                	mv	s5,a2
    80003cea:	84b6                	mv	s1,a3
    80003cec:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cee:	9f35                	addw	a4,a4,a3
    return 0;
    80003cf0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cf2:	0ad76063          	bltu	a4,a3,80003d92 <readi+0xd2>
  if(off + n > ip->size)
    80003cf6:	00e7f463          	bgeu	a5,a4,80003cfe <readi+0x3e>
    n = ip->size - off;
    80003cfa:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cfe:	0a0b0963          	beqz	s6,80003db0 <readi+0xf0>
    80003d02:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d04:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003d08:	5cfd                	li	s9,-1
    80003d0a:	a82d                	j	80003d44 <readi+0x84>
    80003d0c:	020a1d93          	slli	s11,s4,0x20
    80003d10:	020ddd93          	srli	s11,s11,0x20
    80003d14:	05890793          	addi	a5,s2,88
    80003d18:	86ee                	mv	a3,s11
    80003d1a:	963e                	add	a2,a2,a5
    80003d1c:	85d6                	mv	a1,s5
    80003d1e:	8562                	mv	a0,s8
    80003d20:	fffff097          	auipc	ra,0xfffff
    80003d24:	980080e7          	jalr	-1664(ra) # 800026a0 <either_copyout>
    80003d28:	05950d63          	beq	a0,s9,80003d82 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d2c:	854a                	mv	a0,s2
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	60a080e7          	jalr	1546(ra) # 80003338 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d36:	013a09bb          	addw	s3,s4,s3
    80003d3a:	009a04bb          	addw	s1,s4,s1
    80003d3e:	9aee                	add	s5,s5,s11
    80003d40:	0569f763          	bgeu	s3,s6,80003d8e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d44:	000ba903          	lw	s2,0(s7)
    80003d48:	00a4d59b          	srliw	a1,s1,0xa
    80003d4c:	855e                	mv	a0,s7
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	8ae080e7          	jalr	-1874(ra) # 800035fc <bmap>
    80003d56:	0005059b          	sext.w	a1,a0
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	4ac080e7          	jalr	1196(ra) # 80003208 <bread>
    80003d64:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d66:	3ff4f613          	andi	a2,s1,1023
    80003d6a:	40cd07bb          	subw	a5,s10,a2
    80003d6e:	413b073b          	subw	a4,s6,s3
    80003d72:	8a3e                	mv	s4,a5
    80003d74:	2781                	sext.w	a5,a5
    80003d76:	0007069b          	sext.w	a3,a4
    80003d7a:	f8f6f9e3          	bgeu	a3,a5,80003d0c <readi+0x4c>
    80003d7e:	8a3a                	mv	s4,a4
    80003d80:	b771                	j	80003d0c <readi+0x4c>
      brelse(bp);
    80003d82:	854a                	mv	a0,s2
    80003d84:	fffff097          	auipc	ra,0xfffff
    80003d88:	5b4080e7          	jalr	1460(ra) # 80003338 <brelse>
      tot = -1;
    80003d8c:	59fd                	li	s3,-1
  }
  return tot;
    80003d8e:	0009851b          	sext.w	a0,s3
}
    80003d92:	70a6                	ld	ra,104(sp)
    80003d94:	7406                	ld	s0,96(sp)
    80003d96:	64e6                	ld	s1,88(sp)
    80003d98:	6946                	ld	s2,80(sp)
    80003d9a:	69a6                	ld	s3,72(sp)
    80003d9c:	6a06                	ld	s4,64(sp)
    80003d9e:	7ae2                	ld	s5,56(sp)
    80003da0:	7b42                	ld	s6,48(sp)
    80003da2:	7ba2                	ld	s7,40(sp)
    80003da4:	7c02                	ld	s8,32(sp)
    80003da6:	6ce2                	ld	s9,24(sp)
    80003da8:	6d42                	ld	s10,16(sp)
    80003daa:	6da2                	ld	s11,8(sp)
    80003dac:	6165                	addi	sp,sp,112
    80003dae:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003db0:	89da                	mv	s3,s6
    80003db2:	bff1                	j	80003d8e <readi+0xce>
    return 0;
    80003db4:	4501                	li	a0,0
}
    80003db6:	8082                	ret

0000000080003db8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003db8:	457c                	lw	a5,76(a0)
    80003dba:	10d7e863          	bltu	a5,a3,80003eca <writei+0x112>
{
    80003dbe:	7159                	addi	sp,sp,-112
    80003dc0:	f486                	sd	ra,104(sp)
    80003dc2:	f0a2                	sd	s0,96(sp)
    80003dc4:	eca6                	sd	s1,88(sp)
    80003dc6:	e8ca                	sd	s2,80(sp)
    80003dc8:	e4ce                	sd	s3,72(sp)
    80003dca:	e0d2                	sd	s4,64(sp)
    80003dcc:	fc56                	sd	s5,56(sp)
    80003dce:	f85a                	sd	s6,48(sp)
    80003dd0:	f45e                	sd	s7,40(sp)
    80003dd2:	f062                	sd	s8,32(sp)
    80003dd4:	ec66                	sd	s9,24(sp)
    80003dd6:	e86a                	sd	s10,16(sp)
    80003dd8:	e46e                	sd	s11,8(sp)
    80003dda:	1880                	addi	s0,sp,112
    80003ddc:	8b2a                	mv	s6,a0
    80003dde:	8c2e                	mv	s8,a1
    80003de0:	8ab2                	mv	s5,a2
    80003de2:	8936                	mv	s2,a3
    80003de4:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003de6:	00e687bb          	addw	a5,a3,a4
    80003dea:	0ed7e263          	bltu	a5,a3,80003ece <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dee:	00043737          	lui	a4,0x43
    80003df2:	0ef76063          	bltu	a4,a5,80003ed2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003df6:	0c0b8863          	beqz	s7,80003ec6 <writei+0x10e>
    80003dfa:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dfc:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003e00:	5cfd                	li	s9,-1
    80003e02:	a091                	j	80003e46 <writei+0x8e>
    80003e04:	02099d93          	slli	s11,s3,0x20
    80003e08:	020ddd93          	srli	s11,s11,0x20
    80003e0c:	05848793          	addi	a5,s1,88
    80003e10:	86ee                	mv	a3,s11
    80003e12:	8656                	mv	a2,s5
    80003e14:	85e2                	mv	a1,s8
    80003e16:	953e                	add	a0,a0,a5
    80003e18:	fffff097          	auipc	ra,0xfffff
    80003e1c:	8de080e7          	jalr	-1826(ra) # 800026f6 <either_copyin>
    80003e20:	07950263          	beq	a0,s9,80003e84 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e24:	8526                	mv	a0,s1
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	794080e7          	jalr	1940(ra) # 800045ba <log_write>
    brelse(bp);
    80003e2e:	8526                	mv	a0,s1
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	508080e7          	jalr	1288(ra) # 80003338 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e38:	01498a3b          	addw	s4,s3,s4
    80003e3c:	0129893b          	addw	s2,s3,s2
    80003e40:	9aee                	add	s5,s5,s11
    80003e42:	057a7663          	bgeu	s4,s7,80003e8e <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e46:	000b2483          	lw	s1,0(s6)
    80003e4a:	00a9559b          	srliw	a1,s2,0xa
    80003e4e:	855a                	mv	a0,s6
    80003e50:	fffff097          	auipc	ra,0xfffff
    80003e54:	7ac080e7          	jalr	1964(ra) # 800035fc <bmap>
    80003e58:	0005059b          	sext.w	a1,a0
    80003e5c:	8526                	mv	a0,s1
    80003e5e:	fffff097          	auipc	ra,0xfffff
    80003e62:	3aa080e7          	jalr	938(ra) # 80003208 <bread>
    80003e66:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e68:	3ff97513          	andi	a0,s2,1023
    80003e6c:	40ad07bb          	subw	a5,s10,a0
    80003e70:	414b873b          	subw	a4,s7,s4
    80003e74:	89be                	mv	s3,a5
    80003e76:	2781                	sext.w	a5,a5
    80003e78:	0007069b          	sext.w	a3,a4
    80003e7c:	f8f6f4e3          	bgeu	a3,a5,80003e04 <writei+0x4c>
    80003e80:	89ba                	mv	s3,a4
    80003e82:	b749                	j	80003e04 <writei+0x4c>
      brelse(bp);
    80003e84:	8526                	mv	a0,s1
    80003e86:	fffff097          	auipc	ra,0xfffff
    80003e8a:	4b2080e7          	jalr	1202(ra) # 80003338 <brelse>
  }

  if(off > ip->size)
    80003e8e:	04cb2783          	lw	a5,76(s6)
    80003e92:	0127f463          	bgeu	a5,s2,80003e9a <writei+0xe2>
    ip->size = off;
    80003e96:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e9a:	855a                	mv	a0,s6
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	aa6080e7          	jalr	-1370(ra) # 80003942 <iupdate>

  return tot;
    80003ea4:	000a051b          	sext.w	a0,s4
}
    80003ea8:	70a6                	ld	ra,104(sp)
    80003eaa:	7406                	ld	s0,96(sp)
    80003eac:	64e6                	ld	s1,88(sp)
    80003eae:	6946                	ld	s2,80(sp)
    80003eb0:	69a6                	ld	s3,72(sp)
    80003eb2:	6a06                	ld	s4,64(sp)
    80003eb4:	7ae2                	ld	s5,56(sp)
    80003eb6:	7b42                	ld	s6,48(sp)
    80003eb8:	7ba2                	ld	s7,40(sp)
    80003eba:	7c02                	ld	s8,32(sp)
    80003ebc:	6ce2                	ld	s9,24(sp)
    80003ebe:	6d42                	ld	s10,16(sp)
    80003ec0:	6da2                	ld	s11,8(sp)
    80003ec2:	6165                	addi	sp,sp,112
    80003ec4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ec6:	8a5e                	mv	s4,s7
    80003ec8:	bfc9                	j	80003e9a <writei+0xe2>
    return -1;
    80003eca:	557d                	li	a0,-1
}
    80003ecc:	8082                	ret
    return -1;
    80003ece:	557d                	li	a0,-1
    80003ed0:	bfe1                	j	80003ea8 <writei+0xf0>
    return -1;
    80003ed2:	557d                	li	a0,-1
    80003ed4:	bfd1                	j	80003ea8 <writei+0xf0>

0000000080003ed6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ed6:	1141                	addi	sp,sp,-16
    80003ed8:	e406                	sd	ra,8(sp)
    80003eda:	e022                	sd	s0,0(sp)
    80003edc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ede:	4639                	li	a2,14
    80003ee0:	ffffd097          	auipc	ra,0xffffd
    80003ee4:	eb6080e7          	jalr	-330(ra) # 80000d96 <strncmp>
}
    80003ee8:	60a2                	ld	ra,8(sp)
    80003eea:	6402                	ld	s0,0(sp)
    80003eec:	0141                	addi	sp,sp,16
    80003eee:	8082                	ret

0000000080003ef0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ef0:	7139                	addi	sp,sp,-64
    80003ef2:	fc06                	sd	ra,56(sp)
    80003ef4:	f822                	sd	s0,48(sp)
    80003ef6:	f426                	sd	s1,40(sp)
    80003ef8:	f04a                	sd	s2,32(sp)
    80003efa:	ec4e                	sd	s3,24(sp)
    80003efc:	e852                	sd	s4,16(sp)
    80003efe:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003f00:	04451703          	lh	a4,68(a0)
    80003f04:	4785                	li	a5,1
    80003f06:	00f71a63          	bne	a4,a5,80003f1a <dirlookup+0x2a>
    80003f0a:	892a                	mv	s2,a0
    80003f0c:	89ae                	mv	s3,a1
    80003f0e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f10:	457c                	lw	a5,76(a0)
    80003f12:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003f14:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f16:	e79d                	bnez	a5,80003f44 <dirlookup+0x54>
    80003f18:	a8a5                	j	80003f90 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003f1a:	00005517          	auipc	a0,0x5
    80003f1e:	9ce50513          	addi	a0,a0,-1586 # 800088e8 <syscalls_str+0x1b0>
    80003f22:	ffffc097          	auipc	ra,0xffffc
    80003f26:	608080e7          	jalr	1544(ra) # 8000052a <panic>
      panic("dirlookup read");
    80003f2a:	00005517          	auipc	a0,0x5
    80003f2e:	9d650513          	addi	a0,a0,-1578 # 80008900 <syscalls_str+0x1c8>
    80003f32:	ffffc097          	auipc	ra,0xffffc
    80003f36:	5f8080e7          	jalr	1528(ra) # 8000052a <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f3a:	24c1                	addiw	s1,s1,16
    80003f3c:	04c92783          	lw	a5,76(s2)
    80003f40:	04f4f763          	bgeu	s1,a5,80003f8e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f44:	4741                	li	a4,16
    80003f46:	86a6                	mv	a3,s1
    80003f48:	fc040613          	addi	a2,s0,-64
    80003f4c:	4581                	li	a1,0
    80003f4e:	854a                	mv	a0,s2
    80003f50:	00000097          	auipc	ra,0x0
    80003f54:	d70080e7          	jalr	-656(ra) # 80003cc0 <readi>
    80003f58:	47c1                	li	a5,16
    80003f5a:	fcf518e3          	bne	a0,a5,80003f2a <dirlookup+0x3a>
    if(de.inum == 0)
    80003f5e:	fc045783          	lhu	a5,-64(s0)
    80003f62:	dfe1                	beqz	a5,80003f3a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f64:	fc240593          	addi	a1,s0,-62
    80003f68:	854e                	mv	a0,s3
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	f6c080e7          	jalr	-148(ra) # 80003ed6 <namecmp>
    80003f72:	f561                	bnez	a0,80003f3a <dirlookup+0x4a>
      if(poff)
    80003f74:	000a0463          	beqz	s4,80003f7c <dirlookup+0x8c>
        *poff = off;
    80003f78:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f7c:	fc045583          	lhu	a1,-64(s0)
    80003f80:	00092503          	lw	a0,0(s2)
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	754080e7          	jalr	1876(ra) # 800036d8 <iget>
    80003f8c:	a011                	j	80003f90 <dirlookup+0xa0>
  return 0;
    80003f8e:	4501                	li	a0,0
}
    80003f90:	70e2                	ld	ra,56(sp)
    80003f92:	7442                	ld	s0,48(sp)
    80003f94:	74a2                	ld	s1,40(sp)
    80003f96:	7902                	ld	s2,32(sp)
    80003f98:	69e2                	ld	s3,24(sp)
    80003f9a:	6a42                	ld	s4,16(sp)
    80003f9c:	6121                	addi	sp,sp,64
    80003f9e:	8082                	ret

0000000080003fa0 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003fa0:	711d                	addi	sp,sp,-96
    80003fa2:	ec86                	sd	ra,88(sp)
    80003fa4:	e8a2                	sd	s0,80(sp)
    80003fa6:	e4a6                	sd	s1,72(sp)
    80003fa8:	e0ca                	sd	s2,64(sp)
    80003faa:	fc4e                	sd	s3,56(sp)
    80003fac:	f852                	sd	s4,48(sp)
    80003fae:	f456                	sd	s5,40(sp)
    80003fb0:	f05a                	sd	s6,32(sp)
    80003fb2:	ec5e                	sd	s7,24(sp)
    80003fb4:	e862                	sd	s8,16(sp)
    80003fb6:	e466                	sd	s9,8(sp)
    80003fb8:	1080                	addi	s0,sp,96
    80003fba:	84aa                	mv	s1,a0
    80003fbc:	8aae                	mv	s5,a1
    80003fbe:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fc0:	00054703          	lbu	a4,0(a0)
    80003fc4:	02f00793          	li	a5,47
    80003fc8:	02f70363          	beq	a4,a5,80003fee <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fcc:	ffffe097          	auipc	ra,0xffffe
    80003fd0:	9c6080e7          	jalr	-1594(ra) # 80001992 <myproc>
    80003fd4:	16853503          	ld	a0,360(a0)
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	9f6080e7          	jalr	-1546(ra) # 800039ce <idup>
    80003fe0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fe2:	02f00913          	li	s2,47
  len = path - s;
    80003fe6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fe8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fea:	4b85                	li	s7,1
    80003fec:	a865                	j	800040a4 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fee:	4585                	li	a1,1
    80003ff0:	4505                	li	a0,1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	6e6080e7          	jalr	1766(ra) # 800036d8 <iget>
    80003ffa:	89aa                	mv	s3,a0
    80003ffc:	b7dd                	j	80003fe2 <namex+0x42>
      iunlockput(ip);
    80003ffe:	854e                	mv	a0,s3
    80004000:	00000097          	auipc	ra,0x0
    80004004:	c6e080e7          	jalr	-914(ra) # 80003c6e <iunlockput>
      return 0;
    80004008:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000400a:	854e                	mv	a0,s3
    8000400c:	60e6                	ld	ra,88(sp)
    8000400e:	6446                	ld	s0,80(sp)
    80004010:	64a6                	ld	s1,72(sp)
    80004012:	6906                	ld	s2,64(sp)
    80004014:	79e2                	ld	s3,56(sp)
    80004016:	7a42                	ld	s4,48(sp)
    80004018:	7aa2                	ld	s5,40(sp)
    8000401a:	7b02                	ld	s6,32(sp)
    8000401c:	6be2                	ld	s7,24(sp)
    8000401e:	6c42                	ld	s8,16(sp)
    80004020:	6ca2                	ld	s9,8(sp)
    80004022:	6125                	addi	sp,sp,96
    80004024:	8082                	ret
      iunlock(ip);
    80004026:	854e                	mv	a0,s3
    80004028:	00000097          	auipc	ra,0x0
    8000402c:	aa6080e7          	jalr	-1370(ra) # 80003ace <iunlock>
      return ip;
    80004030:	bfe9                	j	8000400a <namex+0x6a>
      iunlockput(ip);
    80004032:	854e                	mv	a0,s3
    80004034:	00000097          	auipc	ra,0x0
    80004038:	c3a080e7          	jalr	-966(ra) # 80003c6e <iunlockput>
      return 0;
    8000403c:	89e6                	mv	s3,s9
    8000403e:	b7f1                	j	8000400a <namex+0x6a>
  len = path - s;
    80004040:	40b48633          	sub	a2,s1,a1
    80004044:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004048:	099c5463          	bge	s8,s9,800040d0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000404c:	4639                	li	a2,14
    8000404e:	8552                	mv	a0,s4
    80004050:	ffffd097          	auipc	ra,0xffffd
    80004054:	cca080e7          	jalr	-822(ra) # 80000d1a <memmove>
  while(*path == '/')
    80004058:	0004c783          	lbu	a5,0(s1)
    8000405c:	01279763          	bne	a5,s2,8000406a <namex+0xca>
    path++;
    80004060:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004062:	0004c783          	lbu	a5,0(s1)
    80004066:	ff278de3          	beq	a5,s2,80004060 <namex+0xc0>
    ilock(ip);
    8000406a:	854e                	mv	a0,s3
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	9a0080e7          	jalr	-1632(ra) # 80003a0c <ilock>
    if(ip->type != T_DIR){
    80004074:	04499783          	lh	a5,68(s3)
    80004078:	f97793e3          	bne	a5,s7,80003ffe <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000407c:	000a8563          	beqz	s5,80004086 <namex+0xe6>
    80004080:	0004c783          	lbu	a5,0(s1)
    80004084:	d3cd                	beqz	a5,80004026 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004086:	865a                	mv	a2,s6
    80004088:	85d2                	mv	a1,s4
    8000408a:	854e                	mv	a0,s3
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	e64080e7          	jalr	-412(ra) # 80003ef0 <dirlookup>
    80004094:	8caa                	mv	s9,a0
    80004096:	dd51                	beqz	a0,80004032 <namex+0x92>
    iunlockput(ip);
    80004098:	854e                	mv	a0,s3
    8000409a:	00000097          	auipc	ra,0x0
    8000409e:	bd4080e7          	jalr	-1068(ra) # 80003c6e <iunlockput>
    ip = next;
    800040a2:	89e6                	mv	s3,s9
  while(*path == '/')
    800040a4:	0004c783          	lbu	a5,0(s1)
    800040a8:	05279763          	bne	a5,s2,800040f6 <namex+0x156>
    path++;
    800040ac:	0485                	addi	s1,s1,1
  while(*path == '/')
    800040ae:	0004c783          	lbu	a5,0(s1)
    800040b2:	ff278de3          	beq	a5,s2,800040ac <namex+0x10c>
  if(*path == 0)
    800040b6:	c79d                	beqz	a5,800040e4 <namex+0x144>
    path++;
    800040b8:	85a6                	mv	a1,s1
  len = path - s;
    800040ba:	8cda                	mv	s9,s6
    800040bc:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    800040be:	01278963          	beq	a5,s2,800040d0 <namex+0x130>
    800040c2:	dfbd                	beqz	a5,80004040 <namex+0xa0>
    path++;
    800040c4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040c6:	0004c783          	lbu	a5,0(s1)
    800040ca:	ff279ce3          	bne	a5,s2,800040c2 <namex+0x122>
    800040ce:	bf8d                	j	80004040 <namex+0xa0>
    memmove(name, s, len);
    800040d0:	2601                	sext.w	a2,a2
    800040d2:	8552                	mv	a0,s4
    800040d4:	ffffd097          	auipc	ra,0xffffd
    800040d8:	c46080e7          	jalr	-954(ra) # 80000d1a <memmove>
    name[len] = 0;
    800040dc:	9cd2                	add	s9,s9,s4
    800040de:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800040e2:	bf9d                	j	80004058 <namex+0xb8>
  if(nameiparent){
    800040e4:	f20a83e3          	beqz	s5,8000400a <namex+0x6a>
    iput(ip);
    800040e8:	854e                	mv	a0,s3
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	adc080e7          	jalr	-1316(ra) # 80003bc6 <iput>
    return 0;
    800040f2:	4981                	li	s3,0
    800040f4:	bf19                	j	8000400a <namex+0x6a>
  if(*path == 0)
    800040f6:	d7fd                	beqz	a5,800040e4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040f8:	0004c783          	lbu	a5,0(s1)
    800040fc:	85a6                	mv	a1,s1
    800040fe:	b7d1                	j	800040c2 <namex+0x122>

0000000080004100 <dirlink>:
{
    80004100:	7139                	addi	sp,sp,-64
    80004102:	fc06                	sd	ra,56(sp)
    80004104:	f822                	sd	s0,48(sp)
    80004106:	f426                	sd	s1,40(sp)
    80004108:	f04a                	sd	s2,32(sp)
    8000410a:	ec4e                	sd	s3,24(sp)
    8000410c:	e852                	sd	s4,16(sp)
    8000410e:	0080                	addi	s0,sp,64
    80004110:	892a                	mv	s2,a0
    80004112:	8a2e                	mv	s4,a1
    80004114:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004116:	4601                	li	a2,0
    80004118:	00000097          	auipc	ra,0x0
    8000411c:	dd8080e7          	jalr	-552(ra) # 80003ef0 <dirlookup>
    80004120:	e93d                	bnez	a0,80004196 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004122:	04c92483          	lw	s1,76(s2)
    80004126:	c49d                	beqz	s1,80004154 <dirlink+0x54>
    80004128:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000412a:	4741                	li	a4,16
    8000412c:	86a6                	mv	a3,s1
    8000412e:	fc040613          	addi	a2,s0,-64
    80004132:	4581                	li	a1,0
    80004134:	854a                	mv	a0,s2
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	b8a080e7          	jalr	-1142(ra) # 80003cc0 <readi>
    8000413e:	47c1                	li	a5,16
    80004140:	06f51163          	bne	a0,a5,800041a2 <dirlink+0xa2>
    if(de.inum == 0)
    80004144:	fc045783          	lhu	a5,-64(s0)
    80004148:	c791                	beqz	a5,80004154 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000414a:	24c1                	addiw	s1,s1,16
    8000414c:	04c92783          	lw	a5,76(s2)
    80004150:	fcf4ede3          	bltu	s1,a5,8000412a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004154:	4639                	li	a2,14
    80004156:	85d2                	mv	a1,s4
    80004158:	fc240513          	addi	a0,s0,-62
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	c76080e7          	jalr	-906(ra) # 80000dd2 <strncpy>
  de.inum = inum;
    80004164:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004168:	4741                	li	a4,16
    8000416a:	86a6                	mv	a3,s1
    8000416c:	fc040613          	addi	a2,s0,-64
    80004170:	4581                	li	a1,0
    80004172:	854a                	mv	a0,s2
    80004174:	00000097          	auipc	ra,0x0
    80004178:	c44080e7          	jalr	-956(ra) # 80003db8 <writei>
    8000417c:	872a                	mv	a4,a0
    8000417e:	47c1                	li	a5,16
  return 0;
    80004180:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004182:	02f71863          	bne	a4,a5,800041b2 <dirlink+0xb2>
}
    80004186:	70e2                	ld	ra,56(sp)
    80004188:	7442                	ld	s0,48(sp)
    8000418a:	74a2                	ld	s1,40(sp)
    8000418c:	7902                	ld	s2,32(sp)
    8000418e:	69e2                	ld	s3,24(sp)
    80004190:	6a42                	ld	s4,16(sp)
    80004192:	6121                	addi	sp,sp,64
    80004194:	8082                	ret
    iput(ip);
    80004196:	00000097          	auipc	ra,0x0
    8000419a:	a30080e7          	jalr	-1488(ra) # 80003bc6 <iput>
    return -1;
    8000419e:	557d                	li	a0,-1
    800041a0:	b7dd                	j	80004186 <dirlink+0x86>
      panic("dirlink read");
    800041a2:	00004517          	auipc	a0,0x4
    800041a6:	76e50513          	addi	a0,a0,1902 # 80008910 <syscalls_str+0x1d8>
    800041aa:	ffffc097          	auipc	ra,0xffffc
    800041ae:	380080e7          	jalr	896(ra) # 8000052a <panic>
    panic("dirlink");
    800041b2:	00005517          	auipc	a0,0x5
    800041b6:	86e50513          	addi	a0,a0,-1938 # 80008a20 <syscalls_str+0x2e8>
    800041ba:	ffffc097          	auipc	ra,0xffffc
    800041be:	370080e7          	jalr	880(ra) # 8000052a <panic>

00000000800041c2 <namei>:

struct inode*
namei(char *path)
{
    800041c2:	1101                	addi	sp,sp,-32
    800041c4:	ec06                	sd	ra,24(sp)
    800041c6:	e822                	sd	s0,16(sp)
    800041c8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041ca:	fe040613          	addi	a2,s0,-32
    800041ce:	4581                	li	a1,0
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	dd0080e7          	jalr	-560(ra) # 80003fa0 <namex>
}
    800041d8:	60e2                	ld	ra,24(sp)
    800041da:	6442                	ld	s0,16(sp)
    800041dc:	6105                	addi	sp,sp,32
    800041de:	8082                	ret

00000000800041e0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041e0:	1141                	addi	sp,sp,-16
    800041e2:	e406                	sd	ra,8(sp)
    800041e4:	e022                	sd	s0,0(sp)
    800041e6:	0800                	addi	s0,sp,16
    800041e8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041ea:	4585                	li	a1,1
    800041ec:	00000097          	auipc	ra,0x0
    800041f0:	db4080e7          	jalr	-588(ra) # 80003fa0 <namex>
}
    800041f4:	60a2                	ld	ra,8(sp)
    800041f6:	6402                	ld	s0,0(sp)
    800041f8:	0141                	addi	sp,sp,16
    800041fa:	8082                	ret

00000000800041fc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041fc:	1101                	addi	sp,sp,-32
    800041fe:	ec06                	sd	ra,24(sp)
    80004200:	e822                	sd	s0,16(sp)
    80004202:	e426                	sd	s1,8(sp)
    80004204:	e04a                	sd	s2,0(sp)
    80004206:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004208:	0001d917          	auipc	s2,0x1d
    8000420c:	66890913          	addi	s2,s2,1640 # 80021870 <log>
    80004210:	01892583          	lw	a1,24(s2)
    80004214:	02892503          	lw	a0,40(s2)
    80004218:	fffff097          	auipc	ra,0xfffff
    8000421c:	ff0080e7          	jalr	-16(ra) # 80003208 <bread>
    80004220:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004222:	02c92683          	lw	a3,44(s2)
    80004226:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004228:	02d05863          	blez	a3,80004258 <write_head+0x5c>
    8000422c:	0001d797          	auipc	a5,0x1d
    80004230:	67478793          	addi	a5,a5,1652 # 800218a0 <log+0x30>
    80004234:	05c50713          	addi	a4,a0,92
    80004238:	36fd                	addiw	a3,a3,-1
    8000423a:	02069613          	slli	a2,a3,0x20
    8000423e:	01e65693          	srli	a3,a2,0x1e
    80004242:	0001d617          	auipc	a2,0x1d
    80004246:	66260613          	addi	a2,a2,1634 # 800218a4 <log+0x34>
    8000424a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000424c:	4390                	lw	a2,0(a5)
    8000424e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004250:	0791                	addi	a5,a5,4
    80004252:	0711                	addi	a4,a4,4
    80004254:	fed79ce3          	bne	a5,a3,8000424c <write_head+0x50>
  }
  bwrite(buf);
    80004258:	8526                	mv	a0,s1
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	0a0080e7          	jalr	160(ra) # 800032fa <bwrite>
  brelse(buf);
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	0d4080e7          	jalr	212(ra) # 80003338 <brelse>
}
    8000426c:	60e2                	ld	ra,24(sp)
    8000426e:	6442                	ld	s0,16(sp)
    80004270:	64a2                	ld	s1,8(sp)
    80004272:	6902                	ld	s2,0(sp)
    80004274:	6105                	addi	sp,sp,32
    80004276:	8082                	ret

0000000080004278 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004278:	0001d797          	auipc	a5,0x1d
    8000427c:	6247a783          	lw	a5,1572(a5) # 8002189c <log+0x2c>
    80004280:	0af05d63          	blez	a5,8000433a <install_trans+0xc2>
{
    80004284:	7139                	addi	sp,sp,-64
    80004286:	fc06                	sd	ra,56(sp)
    80004288:	f822                	sd	s0,48(sp)
    8000428a:	f426                	sd	s1,40(sp)
    8000428c:	f04a                	sd	s2,32(sp)
    8000428e:	ec4e                	sd	s3,24(sp)
    80004290:	e852                	sd	s4,16(sp)
    80004292:	e456                	sd	s5,8(sp)
    80004294:	e05a                	sd	s6,0(sp)
    80004296:	0080                	addi	s0,sp,64
    80004298:	8b2a                	mv	s6,a0
    8000429a:	0001da97          	auipc	s5,0x1d
    8000429e:	606a8a93          	addi	s5,s5,1542 # 800218a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042a4:	0001d997          	auipc	s3,0x1d
    800042a8:	5cc98993          	addi	s3,s3,1484 # 80021870 <log>
    800042ac:	a00d                	j	800042ce <install_trans+0x56>
    brelse(lbuf);
    800042ae:	854a                	mv	a0,s2
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	088080e7          	jalr	136(ra) # 80003338 <brelse>
    brelse(dbuf);
    800042b8:	8526                	mv	a0,s1
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	07e080e7          	jalr	126(ra) # 80003338 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042c2:	2a05                	addiw	s4,s4,1
    800042c4:	0a91                	addi	s5,s5,4
    800042c6:	02c9a783          	lw	a5,44(s3)
    800042ca:	04fa5e63          	bge	s4,a5,80004326 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042ce:	0189a583          	lw	a1,24(s3)
    800042d2:	014585bb          	addw	a1,a1,s4
    800042d6:	2585                	addiw	a1,a1,1
    800042d8:	0289a503          	lw	a0,40(s3)
    800042dc:	fffff097          	auipc	ra,0xfffff
    800042e0:	f2c080e7          	jalr	-212(ra) # 80003208 <bread>
    800042e4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042e6:	000aa583          	lw	a1,0(s5)
    800042ea:	0289a503          	lw	a0,40(s3)
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	f1a080e7          	jalr	-230(ra) # 80003208 <bread>
    800042f6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042f8:	40000613          	li	a2,1024
    800042fc:	05890593          	addi	a1,s2,88
    80004300:	05850513          	addi	a0,a0,88
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	a16080e7          	jalr	-1514(ra) # 80000d1a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000430c:	8526                	mv	a0,s1
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	fec080e7          	jalr	-20(ra) # 800032fa <bwrite>
    if(recovering == 0)
    80004316:	f80b1ce3          	bnez	s6,800042ae <install_trans+0x36>
      bunpin(dbuf);
    8000431a:	8526                	mv	a0,s1
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	0f6080e7          	jalr	246(ra) # 80003412 <bunpin>
    80004324:	b769                	j	800042ae <install_trans+0x36>
}
    80004326:	70e2                	ld	ra,56(sp)
    80004328:	7442                	ld	s0,48(sp)
    8000432a:	74a2                	ld	s1,40(sp)
    8000432c:	7902                	ld	s2,32(sp)
    8000432e:	69e2                	ld	s3,24(sp)
    80004330:	6a42                	ld	s4,16(sp)
    80004332:	6aa2                	ld	s5,8(sp)
    80004334:	6b02                	ld	s6,0(sp)
    80004336:	6121                	addi	sp,sp,64
    80004338:	8082                	ret
    8000433a:	8082                	ret

000000008000433c <initlog>:
{
    8000433c:	7179                	addi	sp,sp,-48
    8000433e:	f406                	sd	ra,40(sp)
    80004340:	f022                	sd	s0,32(sp)
    80004342:	ec26                	sd	s1,24(sp)
    80004344:	e84a                	sd	s2,16(sp)
    80004346:	e44e                	sd	s3,8(sp)
    80004348:	1800                	addi	s0,sp,48
    8000434a:	892a                	mv	s2,a0
    8000434c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000434e:	0001d497          	auipc	s1,0x1d
    80004352:	52248493          	addi	s1,s1,1314 # 80021870 <log>
    80004356:	00004597          	auipc	a1,0x4
    8000435a:	5ca58593          	addi	a1,a1,1482 # 80008920 <syscalls_str+0x1e8>
    8000435e:	8526                	mv	a0,s1
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	7d2080e7          	jalr	2002(ra) # 80000b32 <initlock>
  log.start = sb->logstart;
    80004368:	0149a583          	lw	a1,20(s3)
    8000436c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000436e:	0109a783          	lw	a5,16(s3)
    80004372:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004374:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004378:	854a                	mv	a0,s2
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	e8e080e7          	jalr	-370(ra) # 80003208 <bread>
  log.lh.n = lh->n;
    80004382:	4d34                	lw	a3,88(a0)
    80004384:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004386:	02d05663          	blez	a3,800043b2 <initlog+0x76>
    8000438a:	05c50793          	addi	a5,a0,92
    8000438e:	0001d717          	auipc	a4,0x1d
    80004392:	51270713          	addi	a4,a4,1298 # 800218a0 <log+0x30>
    80004396:	36fd                	addiw	a3,a3,-1
    80004398:	02069613          	slli	a2,a3,0x20
    8000439c:	01e65693          	srli	a3,a2,0x1e
    800043a0:	06050613          	addi	a2,a0,96
    800043a4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800043a6:	4390                	lw	a2,0(a5)
    800043a8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043aa:	0791                	addi	a5,a5,4
    800043ac:	0711                	addi	a4,a4,4
    800043ae:	fed79ce3          	bne	a5,a3,800043a6 <initlog+0x6a>
  brelse(buf);
    800043b2:	fffff097          	auipc	ra,0xfffff
    800043b6:	f86080e7          	jalr	-122(ra) # 80003338 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800043ba:	4505                	li	a0,1
    800043bc:	00000097          	auipc	ra,0x0
    800043c0:	ebc080e7          	jalr	-324(ra) # 80004278 <install_trans>
  log.lh.n = 0;
    800043c4:	0001d797          	auipc	a5,0x1d
    800043c8:	4c07ac23          	sw	zero,1240(a5) # 8002189c <log+0x2c>
  write_head(); // clear the log
    800043cc:	00000097          	auipc	ra,0x0
    800043d0:	e30080e7          	jalr	-464(ra) # 800041fc <write_head>
}
    800043d4:	70a2                	ld	ra,40(sp)
    800043d6:	7402                	ld	s0,32(sp)
    800043d8:	64e2                	ld	s1,24(sp)
    800043da:	6942                	ld	s2,16(sp)
    800043dc:	69a2                	ld	s3,8(sp)
    800043de:	6145                	addi	sp,sp,48
    800043e0:	8082                	ret

00000000800043e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043e2:	1101                	addi	sp,sp,-32
    800043e4:	ec06                	sd	ra,24(sp)
    800043e6:	e822                	sd	s0,16(sp)
    800043e8:	e426                	sd	s1,8(sp)
    800043ea:	e04a                	sd	s2,0(sp)
    800043ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043ee:	0001d517          	auipc	a0,0x1d
    800043f2:	48250513          	addi	a0,a0,1154 # 80021870 <log>
    800043f6:	ffffc097          	auipc	ra,0xffffc
    800043fa:	7cc080e7          	jalr	1996(ra) # 80000bc2 <acquire>
  while(1){
    if(log.committing){
    800043fe:	0001d497          	auipc	s1,0x1d
    80004402:	47248493          	addi	s1,s1,1138 # 80021870 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004406:	4979                	li	s2,30
    80004408:	a039                	j	80004416 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000440a:	85a6                	mv	a1,s1
    8000440c:	8526                	mv	a0,s1
    8000440e:	ffffe097          	auipc	ra,0xffffe
    80004412:	cb4080e7          	jalr	-844(ra) # 800020c2 <sleep>
    if(log.committing){
    80004416:	50dc                	lw	a5,36(s1)
    80004418:	fbed                	bnez	a5,8000440a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000441a:	509c                	lw	a5,32(s1)
    8000441c:	0017871b          	addiw	a4,a5,1
    80004420:	0007069b          	sext.w	a3,a4
    80004424:	0027179b          	slliw	a5,a4,0x2
    80004428:	9fb9                	addw	a5,a5,a4
    8000442a:	0017979b          	slliw	a5,a5,0x1
    8000442e:	54d8                	lw	a4,44(s1)
    80004430:	9fb9                	addw	a5,a5,a4
    80004432:	00f95963          	bge	s2,a5,80004444 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004436:	85a6                	mv	a1,s1
    80004438:	8526                	mv	a0,s1
    8000443a:	ffffe097          	auipc	ra,0xffffe
    8000443e:	c88080e7          	jalr	-888(ra) # 800020c2 <sleep>
    80004442:	bfd1                	j	80004416 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004444:	0001d517          	auipc	a0,0x1d
    80004448:	42c50513          	addi	a0,a0,1068 # 80021870 <log>
    8000444c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000444e:	ffffd097          	auipc	ra,0xffffd
    80004452:	828080e7          	jalr	-2008(ra) # 80000c76 <release>
      break;
    }
  }
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004462:	7139                	addi	sp,sp,-64
    80004464:	fc06                	sd	ra,56(sp)
    80004466:	f822                	sd	s0,48(sp)
    80004468:	f426                	sd	s1,40(sp)
    8000446a:	f04a                	sd	s2,32(sp)
    8000446c:	ec4e                	sd	s3,24(sp)
    8000446e:	e852                	sd	s4,16(sp)
    80004470:	e456                	sd	s5,8(sp)
    80004472:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004474:	0001d497          	auipc	s1,0x1d
    80004478:	3fc48493          	addi	s1,s1,1020 # 80021870 <log>
    8000447c:	8526                	mv	a0,s1
    8000447e:	ffffc097          	auipc	ra,0xffffc
    80004482:	744080e7          	jalr	1860(ra) # 80000bc2 <acquire>
  log.outstanding -= 1;
    80004486:	509c                	lw	a5,32(s1)
    80004488:	37fd                	addiw	a5,a5,-1
    8000448a:	0007891b          	sext.w	s2,a5
    8000448e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004490:	50dc                	lw	a5,36(s1)
    80004492:	e7b9                	bnez	a5,800044e0 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004494:	04091e63          	bnez	s2,800044f0 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004498:	0001d497          	auipc	s1,0x1d
    8000449c:	3d848493          	addi	s1,s1,984 # 80021870 <log>
    800044a0:	4785                	li	a5,1
    800044a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800044a4:	8526                	mv	a0,s1
    800044a6:	ffffc097          	auipc	ra,0xffffc
    800044aa:	7d0080e7          	jalr	2000(ra) # 80000c76 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800044ae:	54dc                	lw	a5,44(s1)
    800044b0:	06f04763          	bgtz	a5,8000451e <end_op+0xbc>
    acquire(&log.lock);
    800044b4:	0001d497          	auipc	s1,0x1d
    800044b8:	3bc48493          	addi	s1,s1,956 # 80021870 <log>
    800044bc:	8526                	mv	a0,s1
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	704080e7          	jalr	1796(ra) # 80000bc2 <acquire>
    log.committing = 0;
    800044c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffe097          	auipc	ra,0xffffe
    800044d0:	d82080e7          	jalr	-638(ra) # 8000224e <wakeup>
    release(&log.lock);
    800044d4:	8526                	mv	a0,s1
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	7a0080e7          	jalr	1952(ra) # 80000c76 <release>
}
    800044de:	a03d                	j	8000450c <end_op+0xaa>
    panic("log.committing");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	44850513          	addi	a0,a0,1096 # 80008928 <syscalls_str+0x1f0>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	042080e7          	jalr	66(ra) # 8000052a <panic>
    wakeup(&log);
    800044f0:	0001d497          	auipc	s1,0x1d
    800044f4:	38048493          	addi	s1,s1,896 # 80021870 <log>
    800044f8:	8526                	mv	a0,s1
    800044fa:	ffffe097          	auipc	ra,0xffffe
    800044fe:	d54080e7          	jalr	-684(ra) # 8000224e <wakeup>
  release(&log.lock);
    80004502:	8526                	mv	a0,s1
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	772080e7          	jalr	1906(ra) # 80000c76 <release>
}
    8000450c:	70e2                	ld	ra,56(sp)
    8000450e:	7442                	ld	s0,48(sp)
    80004510:	74a2                	ld	s1,40(sp)
    80004512:	7902                	ld	s2,32(sp)
    80004514:	69e2                	ld	s3,24(sp)
    80004516:	6a42                	ld	s4,16(sp)
    80004518:	6aa2                	ld	s5,8(sp)
    8000451a:	6121                	addi	sp,sp,64
    8000451c:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000451e:	0001da97          	auipc	s5,0x1d
    80004522:	382a8a93          	addi	s5,s5,898 # 800218a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004526:	0001da17          	auipc	s4,0x1d
    8000452a:	34aa0a13          	addi	s4,s4,842 # 80021870 <log>
    8000452e:	018a2583          	lw	a1,24(s4)
    80004532:	012585bb          	addw	a1,a1,s2
    80004536:	2585                	addiw	a1,a1,1
    80004538:	028a2503          	lw	a0,40(s4)
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	ccc080e7          	jalr	-820(ra) # 80003208 <bread>
    80004544:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004546:	000aa583          	lw	a1,0(s5)
    8000454a:	028a2503          	lw	a0,40(s4)
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	cba080e7          	jalr	-838(ra) # 80003208 <bread>
    80004556:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004558:	40000613          	li	a2,1024
    8000455c:	05850593          	addi	a1,a0,88
    80004560:	05848513          	addi	a0,s1,88
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	7b6080e7          	jalr	1974(ra) # 80000d1a <memmove>
    bwrite(to);  // write the log
    8000456c:	8526                	mv	a0,s1
    8000456e:	fffff097          	auipc	ra,0xfffff
    80004572:	d8c080e7          	jalr	-628(ra) # 800032fa <bwrite>
    brelse(from);
    80004576:	854e                	mv	a0,s3
    80004578:	fffff097          	auipc	ra,0xfffff
    8000457c:	dc0080e7          	jalr	-576(ra) # 80003338 <brelse>
    brelse(to);
    80004580:	8526                	mv	a0,s1
    80004582:	fffff097          	auipc	ra,0xfffff
    80004586:	db6080e7          	jalr	-586(ra) # 80003338 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000458a:	2905                	addiw	s2,s2,1
    8000458c:	0a91                	addi	s5,s5,4
    8000458e:	02ca2783          	lw	a5,44(s4)
    80004592:	f8f94ee3          	blt	s2,a5,8000452e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004596:	00000097          	auipc	ra,0x0
    8000459a:	c66080e7          	jalr	-922(ra) # 800041fc <write_head>
    install_trans(0); // Now install writes to home locations
    8000459e:	4501                	li	a0,0
    800045a0:	00000097          	auipc	ra,0x0
    800045a4:	cd8080e7          	jalr	-808(ra) # 80004278 <install_trans>
    log.lh.n = 0;
    800045a8:	0001d797          	auipc	a5,0x1d
    800045ac:	2e07aa23          	sw	zero,756(a5) # 8002189c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800045b0:	00000097          	auipc	ra,0x0
    800045b4:	c4c080e7          	jalr	-948(ra) # 800041fc <write_head>
    800045b8:	bdf5                	j	800044b4 <end_op+0x52>

00000000800045ba <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800045ba:	1101                	addi	sp,sp,-32
    800045bc:	ec06                	sd	ra,24(sp)
    800045be:	e822                	sd	s0,16(sp)
    800045c0:	e426                	sd	s1,8(sp)
    800045c2:	e04a                	sd	s2,0(sp)
    800045c4:	1000                	addi	s0,sp,32
    800045c6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800045c8:	0001d917          	auipc	s2,0x1d
    800045cc:	2a890913          	addi	s2,s2,680 # 80021870 <log>
    800045d0:	854a                	mv	a0,s2
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	5f0080e7          	jalr	1520(ra) # 80000bc2 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045da:	02c92603          	lw	a2,44(s2)
    800045de:	47f5                	li	a5,29
    800045e0:	06c7c563          	blt	a5,a2,8000464a <log_write+0x90>
    800045e4:	0001d797          	auipc	a5,0x1d
    800045e8:	2a87a783          	lw	a5,680(a5) # 8002188c <log+0x1c>
    800045ec:	37fd                	addiw	a5,a5,-1
    800045ee:	04f65e63          	bge	a2,a5,8000464a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045f2:	0001d797          	auipc	a5,0x1d
    800045f6:	29e7a783          	lw	a5,670(a5) # 80021890 <log+0x20>
    800045fa:	06f05063          	blez	a5,8000465a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045fe:	4781                	li	a5,0
    80004600:	06c05563          	blez	a2,8000466a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004604:	44cc                	lw	a1,12(s1)
    80004606:	0001d717          	auipc	a4,0x1d
    8000460a:	29a70713          	addi	a4,a4,666 # 800218a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000460e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004610:	4314                	lw	a3,0(a4)
    80004612:	04b68c63          	beq	a3,a1,8000466a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004616:	2785                	addiw	a5,a5,1
    80004618:	0711                	addi	a4,a4,4
    8000461a:	fef61be3          	bne	a2,a5,80004610 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000461e:	0621                	addi	a2,a2,8
    80004620:	060a                	slli	a2,a2,0x2
    80004622:	0001d797          	auipc	a5,0x1d
    80004626:	24e78793          	addi	a5,a5,590 # 80021870 <log>
    8000462a:	963e                	add	a2,a2,a5
    8000462c:	44dc                	lw	a5,12(s1)
    8000462e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004630:	8526                	mv	a0,s1
    80004632:	fffff097          	auipc	ra,0xfffff
    80004636:	da4080e7          	jalr	-604(ra) # 800033d6 <bpin>
    log.lh.n++;
    8000463a:	0001d717          	auipc	a4,0x1d
    8000463e:	23670713          	addi	a4,a4,566 # 80021870 <log>
    80004642:	575c                	lw	a5,44(a4)
    80004644:	2785                	addiw	a5,a5,1
    80004646:	d75c                	sw	a5,44(a4)
    80004648:	a835                	j	80004684 <log_write+0xca>
    panic("too big a transaction");
    8000464a:	00004517          	auipc	a0,0x4
    8000464e:	2ee50513          	addi	a0,a0,750 # 80008938 <syscalls_str+0x200>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	ed8080e7          	jalr	-296(ra) # 8000052a <panic>
    panic("log_write outside of trans");
    8000465a:	00004517          	auipc	a0,0x4
    8000465e:	2f650513          	addi	a0,a0,758 # 80008950 <syscalls_str+0x218>
    80004662:	ffffc097          	auipc	ra,0xffffc
    80004666:	ec8080e7          	jalr	-312(ra) # 8000052a <panic>
  log.lh.block[i] = b->blockno;
    8000466a:	00878713          	addi	a4,a5,8
    8000466e:	00271693          	slli	a3,a4,0x2
    80004672:	0001d717          	auipc	a4,0x1d
    80004676:	1fe70713          	addi	a4,a4,510 # 80021870 <log>
    8000467a:	9736                	add	a4,a4,a3
    8000467c:	44d4                	lw	a3,12(s1)
    8000467e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004680:	faf608e3          	beq	a2,a5,80004630 <log_write+0x76>
  }
  release(&log.lock);
    80004684:	0001d517          	auipc	a0,0x1d
    80004688:	1ec50513          	addi	a0,a0,492 # 80021870 <log>
    8000468c:	ffffc097          	auipc	ra,0xffffc
    80004690:	5ea080e7          	jalr	1514(ra) # 80000c76 <release>
}
    80004694:	60e2                	ld	ra,24(sp)
    80004696:	6442                	ld	s0,16(sp)
    80004698:	64a2                	ld	s1,8(sp)
    8000469a:	6902                	ld	s2,0(sp)
    8000469c:	6105                	addi	sp,sp,32
    8000469e:	8082                	ret

00000000800046a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800046a0:	1101                	addi	sp,sp,-32
    800046a2:	ec06                	sd	ra,24(sp)
    800046a4:	e822                	sd	s0,16(sp)
    800046a6:	e426                	sd	s1,8(sp)
    800046a8:	e04a                	sd	s2,0(sp)
    800046aa:	1000                	addi	s0,sp,32
    800046ac:	84aa                	mv	s1,a0
    800046ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800046b0:	00004597          	auipc	a1,0x4
    800046b4:	2c058593          	addi	a1,a1,704 # 80008970 <syscalls_str+0x238>
    800046b8:	0521                	addi	a0,a0,8
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	478080e7          	jalr	1144(ra) # 80000b32 <initlock>
  lk->name = name;
    800046c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046ca:	0204a423          	sw	zero,40(s1)
}
    800046ce:	60e2                	ld	ra,24(sp)
    800046d0:	6442                	ld	s0,16(sp)
    800046d2:	64a2                	ld	s1,8(sp)
    800046d4:	6902                	ld	s2,0(sp)
    800046d6:	6105                	addi	sp,sp,32
    800046d8:	8082                	ret

00000000800046da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046da:	1101                	addi	sp,sp,-32
    800046dc:	ec06                	sd	ra,24(sp)
    800046de:	e822                	sd	s0,16(sp)
    800046e0:	e426                	sd	s1,8(sp)
    800046e2:	e04a                	sd	s2,0(sp)
    800046e4:	1000                	addi	s0,sp,32
    800046e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046e8:	00850913          	addi	s2,a0,8
    800046ec:	854a                	mv	a0,s2
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	4d4080e7          	jalr	1236(ra) # 80000bc2 <acquire>
  while (lk->locked) {
    800046f6:	409c                	lw	a5,0(s1)
    800046f8:	cb89                	beqz	a5,8000470a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046fa:	85ca                	mv	a1,s2
    800046fc:	8526                	mv	a0,s1
    800046fe:	ffffe097          	auipc	ra,0xffffe
    80004702:	9c4080e7          	jalr	-1596(ra) # 800020c2 <sleep>
  while (lk->locked) {
    80004706:	409c                	lw	a5,0(s1)
    80004708:	fbed                	bnez	a5,800046fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000470a:	4785                	li	a5,1
    8000470c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000470e:	ffffd097          	auipc	ra,0xffffd
    80004712:	284080e7          	jalr	644(ra) # 80001992 <myproc>
    80004716:	591c                	lw	a5,48(a0)
    80004718:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000471a:	854a                	mv	a0,s2
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	55a080e7          	jalr	1370(ra) # 80000c76 <release>
}
    80004724:	60e2                	ld	ra,24(sp)
    80004726:	6442                	ld	s0,16(sp)
    80004728:	64a2                	ld	s1,8(sp)
    8000472a:	6902                	ld	s2,0(sp)
    8000472c:	6105                	addi	sp,sp,32
    8000472e:	8082                	ret

0000000080004730 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004730:	1101                	addi	sp,sp,-32
    80004732:	ec06                	sd	ra,24(sp)
    80004734:	e822                	sd	s0,16(sp)
    80004736:	e426                	sd	s1,8(sp)
    80004738:	e04a                	sd	s2,0(sp)
    8000473a:	1000                	addi	s0,sp,32
    8000473c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000473e:	00850913          	addi	s2,a0,8
    80004742:	854a                	mv	a0,s2
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	47e080e7          	jalr	1150(ra) # 80000bc2 <acquire>
  lk->locked = 0;
    8000474c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004750:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004754:	8526                	mv	a0,s1
    80004756:	ffffe097          	auipc	ra,0xffffe
    8000475a:	af8080e7          	jalr	-1288(ra) # 8000224e <wakeup>
  release(&lk->lk);
    8000475e:	854a                	mv	a0,s2
    80004760:	ffffc097          	auipc	ra,0xffffc
    80004764:	516080e7          	jalr	1302(ra) # 80000c76 <release>
}
    80004768:	60e2                	ld	ra,24(sp)
    8000476a:	6442                	ld	s0,16(sp)
    8000476c:	64a2                	ld	s1,8(sp)
    8000476e:	6902                	ld	s2,0(sp)
    80004770:	6105                	addi	sp,sp,32
    80004772:	8082                	ret

0000000080004774 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004774:	7179                	addi	sp,sp,-48
    80004776:	f406                	sd	ra,40(sp)
    80004778:	f022                	sd	s0,32(sp)
    8000477a:	ec26                	sd	s1,24(sp)
    8000477c:	e84a                	sd	s2,16(sp)
    8000477e:	e44e                	sd	s3,8(sp)
    80004780:	1800                	addi	s0,sp,48
    80004782:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004784:	00850913          	addi	s2,a0,8
    80004788:	854a                	mv	a0,s2
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	438080e7          	jalr	1080(ra) # 80000bc2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004792:	409c                	lw	a5,0(s1)
    80004794:	ef99                	bnez	a5,800047b2 <holdingsleep+0x3e>
    80004796:	4481                	li	s1,0
  release(&lk->lk);
    80004798:	854a                	mv	a0,s2
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	4dc080e7          	jalr	1244(ra) # 80000c76 <release>
  return r;
}
    800047a2:	8526                	mv	a0,s1
    800047a4:	70a2                	ld	ra,40(sp)
    800047a6:	7402                	ld	s0,32(sp)
    800047a8:	64e2                	ld	s1,24(sp)
    800047aa:	6942                	ld	s2,16(sp)
    800047ac:	69a2                	ld	s3,8(sp)
    800047ae:	6145                	addi	sp,sp,48
    800047b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800047b2:	0284a983          	lw	s3,40(s1)
    800047b6:	ffffd097          	auipc	ra,0xffffd
    800047ba:	1dc080e7          	jalr	476(ra) # 80001992 <myproc>
    800047be:	5904                	lw	s1,48(a0)
    800047c0:	413484b3          	sub	s1,s1,s3
    800047c4:	0014b493          	seqz	s1,s1
    800047c8:	bfc1                	j	80004798 <holdingsleep+0x24>

00000000800047ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047ca:	1141                	addi	sp,sp,-16
    800047cc:	e406                	sd	ra,8(sp)
    800047ce:	e022                	sd	s0,0(sp)
    800047d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047d2:	00004597          	auipc	a1,0x4
    800047d6:	1ae58593          	addi	a1,a1,430 # 80008980 <syscalls_str+0x248>
    800047da:	0001d517          	auipc	a0,0x1d
    800047de:	1de50513          	addi	a0,a0,478 # 800219b8 <ftable>
    800047e2:	ffffc097          	auipc	ra,0xffffc
    800047e6:	350080e7          	jalr	848(ra) # 80000b32 <initlock>
}
    800047ea:	60a2                	ld	ra,8(sp)
    800047ec:	6402                	ld	s0,0(sp)
    800047ee:	0141                	addi	sp,sp,16
    800047f0:	8082                	ret

00000000800047f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047f2:	1101                	addi	sp,sp,-32
    800047f4:	ec06                	sd	ra,24(sp)
    800047f6:	e822                	sd	s0,16(sp)
    800047f8:	e426                	sd	s1,8(sp)
    800047fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047fc:	0001d517          	auipc	a0,0x1d
    80004800:	1bc50513          	addi	a0,a0,444 # 800219b8 <ftable>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	3be080e7          	jalr	958(ra) # 80000bc2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000480c:	0001d497          	auipc	s1,0x1d
    80004810:	1c448493          	addi	s1,s1,452 # 800219d0 <ftable+0x18>
    80004814:	0001e717          	auipc	a4,0x1e
    80004818:	15c70713          	addi	a4,a4,348 # 80022970 <ftable+0xfb8>
    if(f->ref == 0){
    8000481c:	40dc                	lw	a5,4(s1)
    8000481e:	cf99                	beqz	a5,8000483c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004820:	02848493          	addi	s1,s1,40
    80004824:	fee49ce3          	bne	s1,a4,8000481c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	19050513          	addi	a0,a0,400 # 800219b8 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	446080e7          	jalr	1094(ra) # 80000c76 <release>
  return 0;
    80004838:	4481                	li	s1,0
    8000483a:	a819                	j	80004850 <filealloc+0x5e>
      f->ref = 1;
    8000483c:	4785                	li	a5,1
    8000483e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004840:	0001d517          	auipc	a0,0x1d
    80004844:	17850513          	addi	a0,a0,376 # 800219b8 <ftable>
    80004848:	ffffc097          	auipc	ra,0xffffc
    8000484c:	42e080e7          	jalr	1070(ra) # 80000c76 <release>
}
    80004850:	8526                	mv	a0,s1
    80004852:	60e2                	ld	ra,24(sp)
    80004854:	6442                	ld	s0,16(sp)
    80004856:	64a2                	ld	s1,8(sp)
    80004858:	6105                	addi	sp,sp,32
    8000485a:	8082                	ret

000000008000485c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000485c:	1101                	addi	sp,sp,-32
    8000485e:	ec06                	sd	ra,24(sp)
    80004860:	e822                	sd	s0,16(sp)
    80004862:	e426                	sd	s1,8(sp)
    80004864:	1000                	addi	s0,sp,32
    80004866:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004868:	0001d517          	auipc	a0,0x1d
    8000486c:	15050513          	addi	a0,a0,336 # 800219b8 <ftable>
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	352080e7          	jalr	850(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    80004878:	40dc                	lw	a5,4(s1)
    8000487a:	02f05263          	blez	a5,8000489e <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000487e:	2785                	addiw	a5,a5,1
    80004880:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004882:	0001d517          	auipc	a0,0x1d
    80004886:	13650513          	addi	a0,a0,310 # 800219b8 <ftable>
    8000488a:	ffffc097          	auipc	ra,0xffffc
    8000488e:	3ec080e7          	jalr	1004(ra) # 80000c76 <release>
  return f;
}
    80004892:	8526                	mv	a0,s1
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	6105                	addi	sp,sp,32
    8000489c:	8082                	ret
    panic("filedup");
    8000489e:	00004517          	auipc	a0,0x4
    800048a2:	0ea50513          	addi	a0,a0,234 # 80008988 <syscalls_str+0x250>
    800048a6:	ffffc097          	auipc	ra,0xffffc
    800048aa:	c84080e7          	jalr	-892(ra) # 8000052a <panic>

00000000800048ae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048ae:	7139                	addi	sp,sp,-64
    800048b0:	fc06                	sd	ra,56(sp)
    800048b2:	f822                	sd	s0,48(sp)
    800048b4:	f426                	sd	s1,40(sp)
    800048b6:	f04a                	sd	s2,32(sp)
    800048b8:	ec4e                	sd	s3,24(sp)
    800048ba:	e852                	sd	s4,16(sp)
    800048bc:	e456                	sd	s5,8(sp)
    800048be:	0080                	addi	s0,sp,64
    800048c0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048c2:	0001d517          	auipc	a0,0x1d
    800048c6:	0f650513          	addi	a0,a0,246 # 800219b8 <ftable>
    800048ca:	ffffc097          	auipc	ra,0xffffc
    800048ce:	2f8080e7          	jalr	760(ra) # 80000bc2 <acquire>
  if(f->ref < 1)
    800048d2:	40dc                	lw	a5,4(s1)
    800048d4:	06f05163          	blez	a5,80004936 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048d8:	37fd                	addiw	a5,a5,-1
    800048da:	0007871b          	sext.w	a4,a5
    800048de:	c0dc                	sw	a5,4(s1)
    800048e0:	06e04363          	bgtz	a4,80004946 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048e4:	0004a903          	lw	s2,0(s1)
    800048e8:	0094ca83          	lbu	s5,9(s1)
    800048ec:	0104ba03          	ld	s4,16(s1)
    800048f0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048f4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048f8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048fc:	0001d517          	auipc	a0,0x1d
    80004900:	0bc50513          	addi	a0,a0,188 # 800219b8 <ftable>
    80004904:	ffffc097          	auipc	ra,0xffffc
    80004908:	372080e7          	jalr	882(ra) # 80000c76 <release>

  if(ff.type == FD_PIPE){
    8000490c:	4785                	li	a5,1
    8000490e:	04f90d63          	beq	s2,a5,80004968 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004912:	3979                	addiw	s2,s2,-2
    80004914:	4785                	li	a5,1
    80004916:	0527e063          	bltu	a5,s2,80004956 <fileclose+0xa8>
    begin_op();
    8000491a:	00000097          	auipc	ra,0x0
    8000491e:	ac8080e7          	jalr	-1336(ra) # 800043e2 <begin_op>
    iput(ff.ip);
    80004922:	854e                	mv	a0,s3
    80004924:	fffff097          	auipc	ra,0xfffff
    80004928:	2a2080e7          	jalr	674(ra) # 80003bc6 <iput>
    end_op();
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	b36080e7          	jalr	-1226(ra) # 80004462 <end_op>
    80004934:	a00d                	j	80004956 <fileclose+0xa8>
    panic("fileclose");
    80004936:	00004517          	auipc	a0,0x4
    8000493a:	05a50513          	addi	a0,a0,90 # 80008990 <syscalls_str+0x258>
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	bec080e7          	jalr	-1044(ra) # 8000052a <panic>
    release(&ftable.lock);
    80004946:	0001d517          	auipc	a0,0x1d
    8000494a:	07250513          	addi	a0,a0,114 # 800219b8 <ftable>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	328080e7          	jalr	808(ra) # 80000c76 <release>
  }
}
    80004956:	70e2                	ld	ra,56(sp)
    80004958:	7442                	ld	s0,48(sp)
    8000495a:	74a2                	ld	s1,40(sp)
    8000495c:	7902                	ld	s2,32(sp)
    8000495e:	69e2                	ld	s3,24(sp)
    80004960:	6a42                	ld	s4,16(sp)
    80004962:	6aa2                	ld	s5,8(sp)
    80004964:	6121                	addi	sp,sp,64
    80004966:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004968:	85d6                	mv	a1,s5
    8000496a:	8552                	mv	a0,s4
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	34c080e7          	jalr	844(ra) # 80004cb8 <pipeclose>
    80004974:	b7cd                	j	80004956 <fileclose+0xa8>

0000000080004976 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004976:	715d                	addi	sp,sp,-80
    80004978:	e486                	sd	ra,72(sp)
    8000497a:	e0a2                	sd	s0,64(sp)
    8000497c:	fc26                	sd	s1,56(sp)
    8000497e:	f84a                	sd	s2,48(sp)
    80004980:	f44e                	sd	s3,40(sp)
    80004982:	0880                	addi	s0,sp,80
    80004984:	84aa                	mv	s1,a0
    80004986:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004988:	ffffd097          	auipc	ra,0xffffd
    8000498c:	00a080e7          	jalr	10(ra) # 80001992 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004990:	409c                	lw	a5,0(s1)
    80004992:	37f9                	addiw	a5,a5,-2
    80004994:	4705                	li	a4,1
    80004996:	04f76763          	bltu	a4,a5,800049e4 <filestat+0x6e>
    8000499a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000499c:	6c88                	ld	a0,24(s1)
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	06e080e7          	jalr	110(ra) # 80003a0c <ilock>
    stati(f->ip, &st);
    800049a6:	fb840593          	addi	a1,s0,-72
    800049aa:	6c88                	ld	a0,24(s1)
    800049ac:	fffff097          	auipc	ra,0xfffff
    800049b0:	2ea080e7          	jalr	746(ra) # 80003c96 <stati>
    iunlock(f->ip);
    800049b4:	6c88                	ld	a0,24(s1)
    800049b6:	fffff097          	auipc	ra,0xfffff
    800049ba:	118080e7          	jalr	280(ra) # 80003ace <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049be:	46e1                	li	a3,24
    800049c0:	fb840613          	addi	a2,s0,-72
    800049c4:	85ce                	mv	a1,s3
    800049c6:	06893503          	ld	a0,104(s2)
    800049ca:	ffffd097          	auipc	ra,0xffffd
    800049ce:	c74080e7          	jalr	-908(ra) # 8000163e <copyout>
    800049d2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049d6:	60a6                	ld	ra,72(sp)
    800049d8:	6406                	ld	s0,64(sp)
    800049da:	74e2                	ld	s1,56(sp)
    800049dc:	7942                	ld	s2,48(sp)
    800049de:	79a2                	ld	s3,40(sp)
    800049e0:	6161                	addi	sp,sp,80
    800049e2:	8082                	ret
  return -1;
    800049e4:	557d                	li	a0,-1
    800049e6:	bfc5                	j	800049d6 <filestat+0x60>

00000000800049e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049e8:	7179                	addi	sp,sp,-48
    800049ea:	f406                	sd	ra,40(sp)
    800049ec:	f022                	sd	s0,32(sp)
    800049ee:	ec26                	sd	s1,24(sp)
    800049f0:	e84a                	sd	s2,16(sp)
    800049f2:	e44e                	sd	s3,8(sp)
    800049f4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049f6:	00854783          	lbu	a5,8(a0)
    800049fa:	c3d5                	beqz	a5,80004a9e <fileread+0xb6>
    800049fc:	84aa                	mv	s1,a0
    800049fe:	89ae                	mv	s3,a1
    80004a00:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a02:	411c                	lw	a5,0(a0)
    80004a04:	4705                	li	a4,1
    80004a06:	04e78963          	beq	a5,a4,80004a58 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a0a:	470d                	li	a4,3
    80004a0c:	04e78d63          	beq	a5,a4,80004a66 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a10:	4709                	li	a4,2
    80004a12:	06e79e63          	bne	a5,a4,80004a8e <fileread+0xa6>
    ilock(f->ip);
    80004a16:	6d08                	ld	a0,24(a0)
    80004a18:	fffff097          	auipc	ra,0xfffff
    80004a1c:	ff4080e7          	jalr	-12(ra) # 80003a0c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a20:	874a                	mv	a4,s2
    80004a22:	5094                	lw	a3,32(s1)
    80004a24:	864e                	mv	a2,s3
    80004a26:	4585                	li	a1,1
    80004a28:	6c88                	ld	a0,24(s1)
    80004a2a:	fffff097          	auipc	ra,0xfffff
    80004a2e:	296080e7          	jalr	662(ra) # 80003cc0 <readi>
    80004a32:	892a                	mv	s2,a0
    80004a34:	00a05563          	blez	a0,80004a3e <fileread+0x56>
      f->off += r;
    80004a38:	509c                	lw	a5,32(s1)
    80004a3a:	9fa9                	addw	a5,a5,a0
    80004a3c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a3e:	6c88                	ld	a0,24(s1)
    80004a40:	fffff097          	auipc	ra,0xfffff
    80004a44:	08e080e7          	jalr	142(ra) # 80003ace <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a48:	854a                	mv	a0,s2
    80004a4a:	70a2                	ld	ra,40(sp)
    80004a4c:	7402                	ld	s0,32(sp)
    80004a4e:	64e2                	ld	s1,24(sp)
    80004a50:	6942                	ld	s2,16(sp)
    80004a52:	69a2                	ld	s3,8(sp)
    80004a54:	6145                	addi	sp,sp,48
    80004a56:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a58:	6908                	ld	a0,16(a0)
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	3c0080e7          	jalr	960(ra) # 80004e1a <piperead>
    80004a62:	892a                	mv	s2,a0
    80004a64:	b7d5                	j	80004a48 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a66:	02451783          	lh	a5,36(a0)
    80004a6a:	03079693          	slli	a3,a5,0x30
    80004a6e:	92c1                	srli	a3,a3,0x30
    80004a70:	4725                	li	a4,9
    80004a72:	02d76863          	bltu	a4,a3,80004aa2 <fileread+0xba>
    80004a76:	0792                	slli	a5,a5,0x4
    80004a78:	0001d717          	auipc	a4,0x1d
    80004a7c:	ea070713          	addi	a4,a4,-352 # 80021918 <devsw>
    80004a80:	97ba                	add	a5,a5,a4
    80004a82:	639c                	ld	a5,0(a5)
    80004a84:	c38d                	beqz	a5,80004aa6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a86:	4505                	li	a0,1
    80004a88:	9782                	jalr	a5
    80004a8a:	892a                	mv	s2,a0
    80004a8c:	bf75                	j	80004a48 <fileread+0x60>
    panic("fileread");
    80004a8e:	00004517          	auipc	a0,0x4
    80004a92:	f1250513          	addi	a0,a0,-238 # 800089a0 <syscalls_str+0x268>
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	a94080e7          	jalr	-1388(ra) # 8000052a <panic>
    return -1;
    80004a9e:	597d                	li	s2,-1
    80004aa0:	b765                	j	80004a48 <fileread+0x60>
      return -1;
    80004aa2:	597d                	li	s2,-1
    80004aa4:	b755                	j	80004a48 <fileread+0x60>
    80004aa6:	597d                	li	s2,-1
    80004aa8:	b745                	j	80004a48 <fileread+0x60>

0000000080004aaa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004aaa:	715d                	addi	sp,sp,-80
    80004aac:	e486                	sd	ra,72(sp)
    80004aae:	e0a2                	sd	s0,64(sp)
    80004ab0:	fc26                	sd	s1,56(sp)
    80004ab2:	f84a                	sd	s2,48(sp)
    80004ab4:	f44e                	sd	s3,40(sp)
    80004ab6:	f052                	sd	s4,32(sp)
    80004ab8:	ec56                	sd	s5,24(sp)
    80004aba:	e85a                	sd	s6,16(sp)
    80004abc:	e45e                	sd	s7,8(sp)
    80004abe:	e062                	sd	s8,0(sp)
    80004ac0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004ac2:	00954783          	lbu	a5,9(a0)
    80004ac6:	10078663          	beqz	a5,80004bd2 <filewrite+0x128>
    80004aca:	892a                	mv	s2,a0
    80004acc:	8aae                	mv	s5,a1
    80004ace:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004ad0:	411c                	lw	a5,0(a0)
    80004ad2:	4705                	li	a4,1
    80004ad4:	02e78263          	beq	a5,a4,80004af8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ad8:	470d                	li	a4,3
    80004ada:	02e78663          	beq	a5,a4,80004b06 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ade:	4709                	li	a4,2
    80004ae0:	0ee79163          	bne	a5,a4,80004bc2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ae4:	0ac05d63          	blez	a2,80004b9e <filewrite+0xf4>
    int i = 0;
    80004ae8:	4981                	li	s3,0
    80004aea:	6b05                	lui	s6,0x1
    80004aec:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004af0:	6b85                	lui	s7,0x1
    80004af2:	c00b8b9b          	addiw	s7,s7,-1024
    80004af6:	a861                	j	80004b8e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004af8:	6908                	ld	a0,16(a0)
    80004afa:	00000097          	auipc	ra,0x0
    80004afe:	22e080e7          	jalr	558(ra) # 80004d28 <pipewrite>
    80004b02:	8a2a                	mv	s4,a0
    80004b04:	a045                	j	80004ba4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b06:	02451783          	lh	a5,36(a0)
    80004b0a:	03079693          	slli	a3,a5,0x30
    80004b0e:	92c1                	srli	a3,a3,0x30
    80004b10:	4725                	li	a4,9
    80004b12:	0cd76263          	bltu	a4,a3,80004bd6 <filewrite+0x12c>
    80004b16:	0792                	slli	a5,a5,0x4
    80004b18:	0001d717          	auipc	a4,0x1d
    80004b1c:	e0070713          	addi	a4,a4,-512 # 80021918 <devsw>
    80004b20:	97ba                	add	a5,a5,a4
    80004b22:	679c                	ld	a5,8(a5)
    80004b24:	cbdd                	beqz	a5,80004bda <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004b26:	4505                	li	a0,1
    80004b28:	9782                	jalr	a5
    80004b2a:	8a2a                	mv	s4,a0
    80004b2c:	a8a5                	j	80004ba4 <filewrite+0xfa>
    80004b2e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b32:	00000097          	auipc	ra,0x0
    80004b36:	8b0080e7          	jalr	-1872(ra) # 800043e2 <begin_op>
      ilock(f->ip);
    80004b3a:	01893503          	ld	a0,24(s2)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	ece080e7          	jalr	-306(ra) # 80003a0c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b46:	8762                	mv	a4,s8
    80004b48:	02092683          	lw	a3,32(s2)
    80004b4c:	01598633          	add	a2,s3,s5
    80004b50:	4585                	li	a1,1
    80004b52:	01893503          	ld	a0,24(s2)
    80004b56:	fffff097          	auipc	ra,0xfffff
    80004b5a:	262080e7          	jalr	610(ra) # 80003db8 <writei>
    80004b5e:	84aa                	mv	s1,a0
    80004b60:	00a05763          	blez	a0,80004b6e <filewrite+0xc4>
        f->off += r;
    80004b64:	02092783          	lw	a5,32(s2)
    80004b68:	9fa9                	addw	a5,a5,a0
    80004b6a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b6e:	01893503          	ld	a0,24(s2)
    80004b72:	fffff097          	auipc	ra,0xfffff
    80004b76:	f5c080e7          	jalr	-164(ra) # 80003ace <iunlock>
      end_op();
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	8e8080e7          	jalr	-1816(ra) # 80004462 <end_op>

      if(r != n1){
    80004b82:	009c1f63          	bne	s8,s1,80004ba0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b86:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b8a:	0149db63          	bge	s3,s4,80004ba0 <filewrite+0xf6>
      int n1 = n - i;
    80004b8e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b92:	84be                	mv	s1,a5
    80004b94:	2781                	sext.w	a5,a5
    80004b96:	f8fb5ce3          	bge	s6,a5,80004b2e <filewrite+0x84>
    80004b9a:	84de                	mv	s1,s7
    80004b9c:	bf49                	j	80004b2e <filewrite+0x84>
    int i = 0;
    80004b9e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ba0:	013a1f63          	bne	s4,s3,80004bbe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ba4:	8552                	mv	a0,s4
    80004ba6:	60a6                	ld	ra,72(sp)
    80004ba8:	6406                	ld	s0,64(sp)
    80004baa:	74e2                	ld	s1,56(sp)
    80004bac:	7942                	ld	s2,48(sp)
    80004bae:	79a2                	ld	s3,40(sp)
    80004bb0:	7a02                	ld	s4,32(sp)
    80004bb2:	6ae2                	ld	s5,24(sp)
    80004bb4:	6b42                	ld	s6,16(sp)
    80004bb6:	6ba2                	ld	s7,8(sp)
    80004bb8:	6c02                	ld	s8,0(sp)
    80004bba:	6161                	addi	sp,sp,80
    80004bbc:	8082                	ret
    ret = (i == n ? n : -1);
    80004bbe:	5a7d                	li	s4,-1
    80004bc0:	b7d5                	j	80004ba4 <filewrite+0xfa>
    panic("filewrite");
    80004bc2:	00004517          	auipc	a0,0x4
    80004bc6:	dee50513          	addi	a0,a0,-530 # 800089b0 <syscalls_str+0x278>
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	960080e7          	jalr	-1696(ra) # 8000052a <panic>
    return -1;
    80004bd2:	5a7d                	li	s4,-1
    80004bd4:	bfc1                	j	80004ba4 <filewrite+0xfa>
      return -1;
    80004bd6:	5a7d                	li	s4,-1
    80004bd8:	b7f1                	j	80004ba4 <filewrite+0xfa>
    80004bda:	5a7d                	li	s4,-1
    80004bdc:	b7e1                	j	80004ba4 <filewrite+0xfa>

0000000080004bde <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bde:	7179                	addi	sp,sp,-48
    80004be0:	f406                	sd	ra,40(sp)
    80004be2:	f022                	sd	s0,32(sp)
    80004be4:	ec26                	sd	s1,24(sp)
    80004be6:	e84a                	sd	s2,16(sp)
    80004be8:	e44e                	sd	s3,8(sp)
    80004bea:	e052                	sd	s4,0(sp)
    80004bec:	1800                	addi	s0,sp,48
    80004bee:	84aa                	mv	s1,a0
    80004bf0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bf2:	0005b023          	sd	zero,0(a1)
    80004bf6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bfa:	00000097          	auipc	ra,0x0
    80004bfe:	bf8080e7          	jalr	-1032(ra) # 800047f2 <filealloc>
    80004c02:	e088                	sd	a0,0(s1)
    80004c04:	c551                	beqz	a0,80004c90 <pipealloc+0xb2>
    80004c06:	00000097          	auipc	ra,0x0
    80004c0a:	bec080e7          	jalr	-1044(ra) # 800047f2 <filealloc>
    80004c0e:	00aa3023          	sd	a0,0(s4)
    80004c12:	c92d                	beqz	a0,80004c84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c14:	ffffc097          	auipc	ra,0xffffc
    80004c18:	ebe080e7          	jalr	-322(ra) # 80000ad2 <kalloc>
    80004c1c:	892a                	mv	s2,a0
    80004c1e:	c125                	beqz	a0,80004c7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c20:	4985                	li	s3,1
    80004c22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004c26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004c2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c32:	00004597          	auipc	a1,0x4
    80004c36:	d8e58593          	addi	a1,a1,-626 # 800089c0 <syscalls_str+0x288>
    80004c3a:	ffffc097          	auipc	ra,0xffffc
    80004c3e:	ef8080e7          	jalr	-264(ra) # 80000b32 <initlock>
  (*f0)->type = FD_PIPE;
    80004c42:	609c                	ld	a5,0(s1)
    80004c44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c48:	609c                	ld	a5,0(s1)
    80004c4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c4e:	609c                	ld	a5,0(s1)
    80004c50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c54:	609c                	ld	a5,0(s1)
    80004c56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c5a:	000a3783          	ld	a5,0(s4)
    80004c5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c62:	000a3783          	ld	a5,0(s4)
    80004c66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c6a:	000a3783          	ld	a5,0(s4)
    80004c6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c72:	000a3783          	ld	a5,0(s4)
    80004c76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c7a:	4501                	li	a0,0
    80004c7c:	a025                	j	80004ca4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c7e:	6088                	ld	a0,0(s1)
    80004c80:	e501                	bnez	a0,80004c88 <pipealloc+0xaa>
    80004c82:	a039                	j	80004c90 <pipealloc+0xb2>
    80004c84:	6088                	ld	a0,0(s1)
    80004c86:	c51d                	beqz	a0,80004cb4 <pipealloc+0xd6>
    fileclose(*f0);
    80004c88:	00000097          	auipc	ra,0x0
    80004c8c:	c26080e7          	jalr	-986(ra) # 800048ae <fileclose>
  if(*f1)
    80004c90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c94:	557d                	li	a0,-1
  if(*f1)
    80004c96:	c799                	beqz	a5,80004ca4 <pipealloc+0xc6>
    fileclose(*f1);
    80004c98:	853e                	mv	a0,a5
    80004c9a:	00000097          	auipc	ra,0x0
    80004c9e:	c14080e7          	jalr	-1004(ra) # 800048ae <fileclose>
  return -1;
    80004ca2:	557d                	li	a0,-1
}
    80004ca4:	70a2                	ld	ra,40(sp)
    80004ca6:	7402                	ld	s0,32(sp)
    80004ca8:	64e2                	ld	s1,24(sp)
    80004caa:	6942                	ld	s2,16(sp)
    80004cac:	69a2                	ld	s3,8(sp)
    80004cae:	6a02                	ld	s4,0(sp)
    80004cb0:	6145                	addi	sp,sp,48
    80004cb2:	8082                	ret
  return -1;
    80004cb4:	557d                	li	a0,-1
    80004cb6:	b7fd                	j	80004ca4 <pipealloc+0xc6>

0000000080004cb8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004cb8:	1101                	addi	sp,sp,-32
    80004cba:	ec06                	sd	ra,24(sp)
    80004cbc:	e822                	sd	s0,16(sp)
    80004cbe:	e426                	sd	s1,8(sp)
    80004cc0:	e04a                	sd	s2,0(sp)
    80004cc2:	1000                	addi	s0,sp,32
    80004cc4:	84aa                	mv	s1,a0
    80004cc6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	efa080e7          	jalr	-262(ra) # 80000bc2 <acquire>
  if(writable){
    80004cd0:	02090d63          	beqz	s2,80004d0a <pipeclose+0x52>
    pi->writeopen = 0;
    80004cd4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cd8:	21848513          	addi	a0,s1,536
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	572080e7          	jalr	1394(ra) # 8000224e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ce4:	2204b783          	ld	a5,544(s1)
    80004ce8:	eb95                	bnez	a5,80004d1c <pipeclose+0x64>
    release(&pi->lock);
    80004cea:	8526                	mv	a0,s1
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	f8a080e7          	jalr	-118(ra) # 80000c76 <release>
    kfree((char*)pi);
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	ffffc097          	auipc	ra,0xffffc
    80004cfa:	ce0080e7          	jalr	-800(ra) # 800009d6 <kfree>
  } else
    release(&pi->lock);
}
    80004cfe:	60e2                	ld	ra,24(sp)
    80004d00:	6442                	ld	s0,16(sp)
    80004d02:	64a2                	ld	s1,8(sp)
    80004d04:	6902                	ld	s2,0(sp)
    80004d06:	6105                	addi	sp,sp,32
    80004d08:	8082                	ret
    pi->readopen = 0;
    80004d0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d0e:	21c48513          	addi	a0,s1,540
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	53c080e7          	jalr	1340(ra) # 8000224e <wakeup>
    80004d1a:	b7e9                	j	80004ce4 <pipeclose+0x2c>
    release(&pi->lock);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	f58080e7          	jalr	-168(ra) # 80000c76 <release>
}
    80004d26:	bfe1                	j	80004cfe <pipeclose+0x46>

0000000080004d28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d28:	711d                	addi	sp,sp,-96
    80004d2a:	ec86                	sd	ra,88(sp)
    80004d2c:	e8a2                	sd	s0,80(sp)
    80004d2e:	e4a6                	sd	s1,72(sp)
    80004d30:	e0ca                	sd	s2,64(sp)
    80004d32:	fc4e                	sd	s3,56(sp)
    80004d34:	f852                	sd	s4,48(sp)
    80004d36:	f456                	sd	s5,40(sp)
    80004d38:	f05a                	sd	s6,32(sp)
    80004d3a:	ec5e                	sd	s7,24(sp)
    80004d3c:	e862                	sd	s8,16(sp)
    80004d3e:	1080                	addi	s0,sp,96
    80004d40:	84aa                	mv	s1,a0
    80004d42:	8aae                	mv	s5,a1
    80004d44:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	c4c080e7          	jalr	-948(ra) # 80001992 <myproc>
    80004d4e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d50:	8526                	mv	a0,s1
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	e70080e7          	jalr	-400(ra) # 80000bc2 <acquire>
  while(i < n){
    80004d5a:	0b405363          	blez	s4,80004e00 <pipewrite+0xd8>
  int i = 0;
    80004d5e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d60:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d62:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d66:	21c48b93          	addi	s7,s1,540
    80004d6a:	a089                	j	80004dac <pipewrite+0x84>
      release(&pi->lock);
    80004d6c:	8526                	mv	a0,s1
    80004d6e:	ffffc097          	auipc	ra,0xffffc
    80004d72:	f08080e7          	jalr	-248(ra) # 80000c76 <release>
      return -1;
    80004d76:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d78:	854a                	mv	a0,s2
    80004d7a:	60e6                	ld	ra,88(sp)
    80004d7c:	6446                	ld	s0,80(sp)
    80004d7e:	64a6                	ld	s1,72(sp)
    80004d80:	6906                	ld	s2,64(sp)
    80004d82:	79e2                	ld	s3,56(sp)
    80004d84:	7a42                	ld	s4,48(sp)
    80004d86:	7aa2                	ld	s5,40(sp)
    80004d88:	7b02                	ld	s6,32(sp)
    80004d8a:	6be2                	ld	s7,24(sp)
    80004d8c:	6c42                	ld	s8,16(sp)
    80004d8e:	6125                	addi	sp,sp,96
    80004d90:	8082                	ret
      wakeup(&pi->nread);
    80004d92:	8562                	mv	a0,s8
    80004d94:	ffffd097          	auipc	ra,0xffffd
    80004d98:	4ba080e7          	jalr	1210(ra) # 8000224e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d9c:	85a6                	mv	a1,s1
    80004d9e:	855e                	mv	a0,s7
    80004da0:	ffffd097          	auipc	ra,0xffffd
    80004da4:	322080e7          	jalr	802(ra) # 800020c2 <sleep>
  while(i < n){
    80004da8:	05495d63          	bge	s2,s4,80004e02 <pipewrite+0xda>
    if(pi->readopen == 0 || pr->killed){
    80004dac:	2204a783          	lw	a5,544(s1)
    80004db0:	dfd5                	beqz	a5,80004d6c <pipewrite+0x44>
    80004db2:	0289a783          	lw	a5,40(s3)
    80004db6:	fbdd                	bnez	a5,80004d6c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004db8:	2184a783          	lw	a5,536(s1)
    80004dbc:	21c4a703          	lw	a4,540(s1)
    80004dc0:	2007879b          	addiw	a5,a5,512
    80004dc4:	fcf707e3          	beq	a4,a5,80004d92 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dc8:	4685                	li	a3,1
    80004dca:	01590633          	add	a2,s2,s5
    80004dce:	faf40593          	addi	a1,s0,-81
    80004dd2:	0689b503          	ld	a0,104(s3)
    80004dd6:	ffffd097          	auipc	ra,0xffffd
    80004dda:	8f4080e7          	jalr	-1804(ra) # 800016ca <copyin>
    80004dde:	03650263          	beq	a0,s6,80004e02 <pipewrite+0xda>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004de2:	21c4a783          	lw	a5,540(s1)
    80004de6:	0017871b          	addiw	a4,a5,1
    80004dea:	20e4ae23          	sw	a4,540(s1)
    80004dee:	1ff7f793          	andi	a5,a5,511
    80004df2:	97a6                	add	a5,a5,s1
    80004df4:	faf44703          	lbu	a4,-81(s0)
    80004df8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004dfc:	2905                	addiw	s2,s2,1
    80004dfe:	b76d                	j	80004da8 <pipewrite+0x80>
  int i = 0;
    80004e00:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004e02:	21848513          	addi	a0,s1,536
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	448080e7          	jalr	1096(ra) # 8000224e <wakeup>
  release(&pi->lock);
    80004e0e:	8526                	mv	a0,s1
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	e66080e7          	jalr	-410(ra) # 80000c76 <release>
  return i;
    80004e18:	b785                	j	80004d78 <pipewrite+0x50>

0000000080004e1a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e1a:	715d                	addi	sp,sp,-80
    80004e1c:	e486                	sd	ra,72(sp)
    80004e1e:	e0a2                	sd	s0,64(sp)
    80004e20:	fc26                	sd	s1,56(sp)
    80004e22:	f84a                	sd	s2,48(sp)
    80004e24:	f44e                	sd	s3,40(sp)
    80004e26:	f052                	sd	s4,32(sp)
    80004e28:	ec56                	sd	s5,24(sp)
    80004e2a:	e85a                	sd	s6,16(sp)
    80004e2c:	0880                	addi	s0,sp,80
    80004e2e:	84aa                	mv	s1,a0
    80004e30:	892e                	mv	s2,a1
    80004e32:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e34:	ffffd097          	auipc	ra,0xffffd
    80004e38:	b5e080e7          	jalr	-1186(ra) # 80001992 <myproc>
    80004e3c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e3e:	8526                	mv	a0,s1
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	d82080e7          	jalr	-638(ra) # 80000bc2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e48:	2184a703          	lw	a4,536(s1)
    80004e4c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e50:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e54:	02f71463          	bne	a4,a5,80004e7c <piperead+0x62>
    80004e58:	2244a783          	lw	a5,548(s1)
    80004e5c:	c385                	beqz	a5,80004e7c <piperead+0x62>
    if(pr->killed){
    80004e5e:	028a2783          	lw	a5,40(s4)
    80004e62:	ebc1                	bnez	a5,80004ef2 <piperead+0xd8>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e64:	85a6                	mv	a1,s1
    80004e66:	854e                	mv	a0,s3
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	25a080e7          	jalr	602(ra) # 800020c2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e70:	2184a703          	lw	a4,536(s1)
    80004e74:	21c4a783          	lw	a5,540(s1)
    80004e78:	fef700e3          	beq	a4,a5,80004e58 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e7c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e7e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e80:	05505363          	blez	s5,80004ec6 <piperead+0xac>
    if(pi->nread == pi->nwrite)
    80004e84:	2184a783          	lw	a5,536(s1)
    80004e88:	21c4a703          	lw	a4,540(s1)
    80004e8c:	02f70d63          	beq	a4,a5,80004ec6 <piperead+0xac>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e90:	0017871b          	addiw	a4,a5,1
    80004e94:	20e4ac23          	sw	a4,536(s1)
    80004e98:	1ff7f793          	andi	a5,a5,511
    80004e9c:	97a6                	add	a5,a5,s1
    80004e9e:	0187c783          	lbu	a5,24(a5)
    80004ea2:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ea6:	4685                	li	a3,1
    80004ea8:	fbf40613          	addi	a2,s0,-65
    80004eac:	85ca                	mv	a1,s2
    80004eae:	068a3503          	ld	a0,104(s4)
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	78c080e7          	jalr	1932(ra) # 8000163e <copyout>
    80004eba:	01650663          	beq	a0,s6,80004ec6 <piperead+0xac>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ebe:	2985                	addiw	s3,s3,1
    80004ec0:	0905                	addi	s2,s2,1
    80004ec2:	fd3a91e3          	bne	s5,s3,80004e84 <piperead+0x6a>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ec6:	21c48513          	addi	a0,s1,540
    80004eca:	ffffd097          	auipc	ra,0xffffd
    80004ece:	384080e7          	jalr	900(ra) # 8000224e <wakeup>
  release(&pi->lock);
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	ffffc097          	auipc	ra,0xffffc
    80004ed8:	da2080e7          	jalr	-606(ra) # 80000c76 <release>
  return i;
}
    80004edc:	854e                	mv	a0,s3
    80004ede:	60a6                	ld	ra,72(sp)
    80004ee0:	6406                	ld	s0,64(sp)
    80004ee2:	74e2                	ld	s1,56(sp)
    80004ee4:	7942                	ld	s2,48(sp)
    80004ee6:	79a2                	ld	s3,40(sp)
    80004ee8:	7a02                	ld	s4,32(sp)
    80004eea:	6ae2                	ld	s5,24(sp)
    80004eec:	6b42                	ld	s6,16(sp)
    80004eee:	6161                	addi	sp,sp,80
    80004ef0:	8082                	ret
      release(&pi->lock);
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	ffffc097          	auipc	ra,0xffffc
    80004ef8:	d82080e7          	jalr	-638(ra) # 80000c76 <release>
      return -1;
    80004efc:	59fd                	li	s3,-1
    80004efe:	bff9                	j	80004edc <piperead+0xc2>

0000000080004f00 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f00:	de010113          	addi	sp,sp,-544
    80004f04:	20113c23          	sd	ra,536(sp)
    80004f08:	20813823          	sd	s0,528(sp)
    80004f0c:	20913423          	sd	s1,520(sp)
    80004f10:	21213023          	sd	s2,512(sp)
    80004f14:	ffce                	sd	s3,504(sp)
    80004f16:	fbd2                	sd	s4,496(sp)
    80004f18:	f7d6                	sd	s5,488(sp)
    80004f1a:	f3da                	sd	s6,480(sp)
    80004f1c:	efde                	sd	s7,472(sp)
    80004f1e:	ebe2                	sd	s8,464(sp)
    80004f20:	e7e6                	sd	s9,456(sp)
    80004f22:	e3ea                	sd	s10,448(sp)
    80004f24:	ff6e                	sd	s11,440(sp)
    80004f26:	1400                	addi	s0,sp,544
    80004f28:	892a                	mv	s2,a0
    80004f2a:	dea43423          	sd	a0,-536(s0)
    80004f2e:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f32:	ffffd097          	auipc	ra,0xffffd
    80004f36:	a60080e7          	jalr	-1440(ra) # 80001992 <myproc>
    80004f3a:	84aa                	mv	s1,a0

  begin_op();
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	4a6080e7          	jalr	1190(ra) # 800043e2 <begin_op>

  if((ip = namei(path)) == 0){
    80004f44:	854a                	mv	a0,s2
    80004f46:	fffff097          	auipc	ra,0xfffff
    80004f4a:	27c080e7          	jalr	636(ra) # 800041c2 <namei>
    80004f4e:	c93d                	beqz	a0,80004fc4 <exec+0xc4>
    80004f50:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	aba080e7          	jalr	-1350(ra) # 80003a0c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f5a:	04000713          	li	a4,64
    80004f5e:	4681                	li	a3,0
    80004f60:	e4840613          	addi	a2,s0,-440
    80004f64:	4581                	li	a1,0
    80004f66:	8556                	mv	a0,s5
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	d58080e7          	jalr	-680(ra) # 80003cc0 <readi>
    80004f70:	04000793          	li	a5,64
    80004f74:	00f51a63          	bne	a0,a5,80004f88 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f78:	e4842703          	lw	a4,-440(s0)
    80004f7c:	464c47b7          	lui	a5,0x464c4
    80004f80:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f84:	04f70663          	beq	a4,a5,80004fd0 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f88:	8556                	mv	a0,s5
    80004f8a:	fffff097          	auipc	ra,0xfffff
    80004f8e:	ce4080e7          	jalr	-796(ra) # 80003c6e <iunlockput>
    end_op();
    80004f92:	fffff097          	auipc	ra,0xfffff
    80004f96:	4d0080e7          	jalr	1232(ra) # 80004462 <end_op>
  }
  return -1;
    80004f9a:	557d                	li	a0,-1
}
    80004f9c:	21813083          	ld	ra,536(sp)
    80004fa0:	21013403          	ld	s0,528(sp)
    80004fa4:	20813483          	ld	s1,520(sp)
    80004fa8:	20013903          	ld	s2,512(sp)
    80004fac:	79fe                	ld	s3,504(sp)
    80004fae:	7a5e                	ld	s4,496(sp)
    80004fb0:	7abe                	ld	s5,488(sp)
    80004fb2:	7b1e                	ld	s6,480(sp)
    80004fb4:	6bfe                	ld	s7,472(sp)
    80004fb6:	6c5e                	ld	s8,464(sp)
    80004fb8:	6cbe                	ld	s9,456(sp)
    80004fba:	6d1e                	ld	s10,448(sp)
    80004fbc:	7dfa                	ld	s11,440(sp)
    80004fbe:	22010113          	addi	sp,sp,544
    80004fc2:	8082                	ret
    end_op();
    80004fc4:	fffff097          	auipc	ra,0xfffff
    80004fc8:	49e080e7          	jalr	1182(ra) # 80004462 <end_op>
    return -1;
    80004fcc:	557d                	li	a0,-1
    80004fce:	b7f9                	j	80004f9c <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fd0:	8526                	mv	a0,s1
    80004fd2:	ffffd097          	auipc	ra,0xffffd
    80004fd6:	a84080e7          	jalr	-1404(ra) # 80001a56 <proc_pagetable>
    80004fda:	8b2a                	mv	s6,a0
    80004fdc:	d555                	beqz	a0,80004f88 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fde:	e6842783          	lw	a5,-408(s0)
    80004fe2:	e8045703          	lhu	a4,-384(s0)
    80004fe6:	c735                	beqz	a4,80005052 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fe8:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fea:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004fee:	6a05                	lui	s4,0x1
    80004ff0:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ff4:	dee43023          	sd	a4,-544(s0)
  uint64 pa;

  if((va % PGSIZE) != 0)
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    80004ff8:	6d85                	lui	s11,0x1
    80004ffa:	7d7d                	lui	s10,0xfffff
    80004ffc:	ac1d                	j	80005232 <exec+0x332>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ffe:	00004517          	auipc	a0,0x4
    80005002:	9ca50513          	addi	a0,a0,-1590 # 800089c8 <syscalls_str+0x290>
    80005006:	ffffb097          	auipc	ra,0xffffb
    8000500a:	524080e7          	jalr	1316(ra) # 8000052a <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000500e:	874a                	mv	a4,s2
    80005010:	009c86bb          	addw	a3,s9,s1
    80005014:	4581                	li	a1,0
    80005016:	8556                	mv	a0,s5
    80005018:	fffff097          	auipc	ra,0xfffff
    8000501c:	ca8080e7          	jalr	-856(ra) # 80003cc0 <readi>
    80005020:	2501                	sext.w	a0,a0
    80005022:	1aa91863          	bne	s2,a0,800051d2 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80005026:	009d84bb          	addw	s1,s11,s1
    8000502a:	013d09bb          	addw	s3,s10,s3
    8000502e:	1f74f263          	bgeu	s1,s7,80005212 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80005032:	02049593          	slli	a1,s1,0x20
    80005036:	9181                	srli	a1,a1,0x20
    80005038:	95e2                	add	a1,a1,s8
    8000503a:	855a                	mv	a0,s6
    8000503c:	ffffc097          	auipc	ra,0xffffc
    80005040:	010080e7          	jalr	16(ra) # 8000104c <walkaddr>
    80005044:	862a                	mv	a2,a0
    if(pa == 0)
    80005046:	dd45                	beqz	a0,80004ffe <exec+0xfe>
      n = PGSIZE;
    80005048:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000504a:	fd49f2e3          	bgeu	s3,s4,8000500e <exec+0x10e>
      n = sz - i;
    8000504e:	894e                	mv	s2,s3
    80005050:	bf7d                	j	8000500e <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005052:	4481                	li	s1,0
  iunlockput(ip);
    80005054:	8556                	mv	a0,s5
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	c18080e7          	jalr	-1000(ra) # 80003c6e <iunlockput>
  end_op();
    8000505e:	fffff097          	auipc	ra,0xfffff
    80005062:	404080e7          	jalr	1028(ra) # 80004462 <end_op>
  p = myproc();
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	92c080e7          	jalr	-1748(ra) # 80001992 <myproc>
    8000506e:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005070:	06053d03          	ld	s10,96(a0)
  sz = PGROUNDUP(sz);
    80005074:	6785                	lui	a5,0x1
    80005076:	17fd                	addi	a5,a5,-1
    80005078:	94be                	add	s1,s1,a5
    8000507a:	77fd                	lui	a5,0xfffff
    8000507c:	8fe5                	and	a5,a5,s1
    8000507e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005082:	6609                	lui	a2,0x2
    80005084:	963e                	add	a2,a2,a5
    80005086:	85be                	mv	a1,a5
    80005088:	855a                	mv	a0,s6
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	364080e7          	jalr	868(ra) # 800013ee <uvmalloc>
    80005092:	8c2a                	mv	s8,a0
  ip = 0;
    80005094:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005096:	12050e63          	beqz	a0,800051d2 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000509a:	75f9                	lui	a1,0xffffe
    8000509c:	95aa                	add	a1,a1,a0
    8000509e:	855a                	mv	a0,s6
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	56c080e7          	jalr	1388(ra) # 8000160c <uvmclear>
  stackbase = sp - PGSIZE;
    800050a8:	7afd                	lui	s5,0xfffff
    800050aa:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800050ac:	df043783          	ld	a5,-528(s0)
    800050b0:	6388                	ld	a0,0(a5)
    800050b2:	c925                	beqz	a0,80005122 <exec+0x222>
    800050b4:	e8840993          	addi	s3,s0,-376
    800050b8:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800050bc:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800050be:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	d82080e7          	jalr	-638(ra) # 80000e42 <strlen>
    800050c8:	0015079b          	addiw	a5,a0,1
    800050cc:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050d0:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050d4:	13596363          	bltu	s2,s5,800051fa <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050d8:	df043d83          	ld	s11,-528(s0)
    800050dc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800050e0:	8552                	mv	a0,s4
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	d60080e7          	jalr	-672(ra) # 80000e42 <strlen>
    800050ea:	0015069b          	addiw	a3,a0,1
    800050ee:	8652                	mv	a2,s4
    800050f0:	85ca                	mv	a1,s2
    800050f2:	855a                	mv	a0,s6
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	54a080e7          	jalr	1354(ra) # 8000163e <copyout>
    800050fc:	10054363          	bltz	a0,80005202 <exec+0x302>
    ustack[argc] = sp;
    80005100:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005104:	0485                	addi	s1,s1,1
    80005106:	008d8793          	addi	a5,s11,8
    8000510a:	def43823          	sd	a5,-528(s0)
    8000510e:	008db503          	ld	a0,8(s11)
    80005112:	c911                	beqz	a0,80005126 <exec+0x226>
    if(argc >= MAXARG)
    80005114:	09a1                	addi	s3,s3,8
    80005116:	fb3c95e3          	bne	s9,s3,800050c0 <exec+0x1c0>
  sz = sz1;
    8000511a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000511e:	4a81                	li	s5,0
    80005120:	a84d                	j	800051d2 <exec+0x2d2>
  sp = sz;
    80005122:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005124:	4481                	li	s1,0
  ustack[argc] = 0;
    80005126:	00349793          	slli	a5,s1,0x3
    8000512a:	f9040713          	addi	a4,s0,-112
    8000512e:	97ba                	add	a5,a5,a4
    80005130:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80005134:	00148693          	addi	a3,s1,1
    80005138:	068e                	slli	a3,a3,0x3
    8000513a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000513e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005142:	01597663          	bgeu	s2,s5,8000514e <exec+0x24e>
  sz = sz1;
    80005146:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000514a:	4a81                	li	s5,0
    8000514c:	a059                	j	800051d2 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000514e:	e8840613          	addi	a2,s0,-376
    80005152:	85ca                	mv	a1,s2
    80005154:	855a                	mv	a0,s6
    80005156:	ffffc097          	auipc	ra,0xffffc
    8000515a:	4e8080e7          	jalr	1256(ra) # 8000163e <copyout>
    8000515e:	0a054663          	bltz	a0,8000520a <exec+0x30a>
  p->trapframe->a1 = sp;
    80005162:	070bb783          	ld	a5,112(s7) # 1070 <_entry-0x7fffef90>
    80005166:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000516a:	de843783          	ld	a5,-536(s0)
    8000516e:	0007c703          	lbu	a4,0(a5)
    80005172:	cf11                	beqz	a4,8000518e <exec+0x28e>
    80005174:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005176:	02f00693          	li	a3,47
    8000517a:	a039                	j	80005188 <exec+0x288>
      last = s+1;
    8000517c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005180:	0785                	addi	a5,a5,1
    80005182:	fff7c703          	lbu	a4,-1(a5)
    80005186:	c701                	beqz	a4,8000518e <exec+0x28e>
    if(*s == '/')
    80005188:	fed71ce3          	bne	a4,a3,80005180 <exec+0x280>
    8000518c:	bfc5                	j	8000517c <exec+0x27c>
  safestrcpy(p->name, last, sizeof(p->name));
    8000518e:	4641                	li	a2,16
    80005190:	de843583          	ld	a1,-536(s0)
    80005194:	170b8513          	addi	a0,s7,368
    80005198:	ffffc097          	auipc	ra,0xffffc
    8000519c:	c78080e7          	jalr	-904(ra) # 80000e10 <safestrcpy>
  oldpagetable = p->pagetable;
    800051a0:	068bb503          	ld	a0,104(s7)
  p->pagetable = pagetable;
    800051a4:	076bb423          	sd	s6,104(s7)
  p->sz = sz;
    800051a8:	078bb023          	sd	s8,96(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051ac:	070bb783          	ld	a5,112(s7)
    800051b0:	e6043703          	ld	a4,-416(s0)
    800051b4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051b6:	070bb783          	ld	a5,112(s7)
    800051ba:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051be:	85ea                	mv	a1,s10
    800051c0:	ffffd097          	auipc	ra,0xffffd
    800051c4:	932080e7          	jalr	-1742(ra) # 80001af2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051c8:	0004851b          	sext.w	a0,s1
    800051cc:	bbc1                	j	80004f9c <exec+0x9c>
    800051ce:	de943c23          	sd	s1,-520(s0)
    proc_freepagetable(pagetable, sz);
    800051d2:	df843583          	ld	a1,-520(s0)
    800051d6:	855a                	mv	a0,s6
    800051d8:	ffffd097          	auipc	ra,0xffffd
    800051dc:	91a080e7          	jalr	-1766(ra) # 80001af2 <proc_freepagetable>
  if(ip){
    800051e0:	da0a94e3          	bnez	s5,80004f88 <exec+0x88>
  return -1;
    800051e4:	557d                	li	a0,-1
    800051e6:	bb5d                	j	80004f9c <exec+0x9c>
    800051e8:	de943c23          	sd	s1,-520(s0)
    800051ec:	b7dd                	j	800051d2 <exec+0x2d2>
    800051ee:	de943c23          	sd	s1,-520(s0)
    800051f2:	b7c5                	j	800051d2 <exec+0x2d2>
    800051f4:	de943c23          	sd	s1,-520(s0)
    800051f8:	bfe9                	j	800051d2 <exec+0x2d2>
  sz = sz1;
    800051fa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051fe:	4a81                	li	s5,0
    80005200:	bfc9                	j	800051d2 <exec+0x2d2>
  sz = sz1;
    80005202:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005206:	4a81                	li	s5,0
    80005208:	b7e9                	j	800051d2 <exec+0x2d2>
  sz = sz1;
    8000520a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000520e:	4a81                	li	s5,0
    80005210:	b7c9                	j	800051d2 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005212:	df843483          	ld	s1,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005216:	e0843783          	ld	a5,-504(s0)
    8000521a:	0017869b          	addiw	a3,a5,1
    8000521e:	e0d43423          	sd	a3,-504(s0)
    80005222:	e0043783          	ld	a5,-512(s0)
    80005226:	0387879b          	addiw	a5,a5,56
    8000522a:	e8045703          	lhu	a4,-384(s0)
    8000522e:	e2e6d3e3          	bge	a3,a4,80005054 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005232:	2781                	sext.w	a5,a5
    80005234:	e0f43023          	sd	a5,-512(s0)
    80005238:	03800713          	li	a4,56
    8000523c:	86be                	mv	a3,a5
    8000523e:	e1040613          	addi	a2,s0,-496
    80005242:	4581                	li	a1,0
    80005244:	8556                	mv	a0,s5
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	a7a080e7          	jalr	-1414(ra) # 80003cc0 <readi>
    8000524e:	03800793          	li	a5,56
    80005252:	f6f51ee3          	bne	a0,a5,800051ce <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80005256:	e1042783          	lw	a5,-496(s0)
    8000525a:	4705                	li	a4,1
    8000525c:	fae79de3          	bne	a5,a4,80005216 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80005260:	e3843603          	ld	a2,-456(s0)
    80005264:	e3043783          	ld	a5,-464(s0)
    80005268:	f8f660e3          	bltu	a2,a5,800051e8 <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000526c:	e2043783          	ld	a5,-480(s0)
    80005270:	963e                	add	a2,a2,a5
    80005272:	f6f66ee3          	bltu	a2,a5,800051ee <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005276:	85a6                	mv	a1,s1
    80005278:	855a                	mv	a0,s6
    8000527a:	ffffc097          	auipc	ra,0xffffc
    8000527e:	174080e7          	jalr	372(ra) # 800013ee <uvmalloc>
    80005282:	dea43c23          	sd	a0,-520(s0)
    80005286:	d53d                	beqz	a0,800051f4 <exec+0x2f4>
    if(ph.vaddr % PGSIZE != 0)
    80005288:	e2043c03          	ld	s8,-480(s0)
    8000528c:	de043783          	ld	a5,-544(s0)
    80005290:	00fc77b3          	and	a5,s8,a5
    80005294:	ff9d                	bnez	a5,800051d2 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005296:	e1842c83          	lw	s9,-488(s0)
    8000529a:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000529e:	f60b8ae3          	beqz	s7,80005212 <exec+0x312>
    800052a2:	89de                	mv	s3,s7
    800052a4:	4481                	li	s1,0
    800052a6:	b371                	j	80005032 <exec+0x132>

00000000800052a8 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052a8:	7179                	addi	sp,sp,-48
    800052aa:	f406                	sd	ra,40(sp)
    800052ac:	f022                	sd	s0,32(sp)
    800052ae:	ec26                	sd	s1,24(sp)
    800052b0:	e84a                	sd	s2,16(sp)
    800052b2:	1800                	addi	s0,sp,48
    800052b4:	892e                	mv	s2,a1
    800052b6:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052b8:	fdc40593          	addi	a1,s0,-36
    800052bc:	ffffe097          	auipc	ra,0xffffe
    800052c0:	aac080e7          	jalr	-1364(ra) # 80002d68 <argint>
    800052c4:	04054063          	bltz	a0,80005304 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052c8:	fdc42703          	lw	a4,-36(s0)
    800052cc:	47bd                	li	a5,15
    800052ce:	02e7ed63          	bltu	a5,a4,80005308 <argfd+0x60>
    800052d2:	ffffc097          	auipc	ra,0xffffc
    800052d6:	6c0080e7          	jalr	1728(ra) # 80001992 <myproc>
    800052da:	fdc42703          	lw	a4,-36(s0)
    800052de:	01c70793          	addi	a5,a4,28
    800052e2:	078e                	slli	a5,a5,0x3
    800052e4:	953e                	add	a0,a0,a5
    800052e6:	651c                	ld	a5,8(a0)
    800052e8:	c395                	beqz	a5,8000530c <argfd+0x64>
    return -1;
  if(pfd)
    800052ea:	00090463          	beqz	s2,800052f2 <argfd+0x4a>
    *pfd = fd;
    800052ee:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052f2:	4501                	li	a0,0
  if(pf)
    800052f4:	c091                	beqz	s1,800052f8 <argfd+0x50>
    *pf = f;
    800052f6:	e09c                	sd	a5,0(s1)
}
    800052f8:	70a2                	ld	ra,40(sp)
    800052fa:	7402                	ld	s0,32(sp)
    800052fc:	64e2                	ld	s1,24(sp)
    800052fe:	6942                	ld	s2,16(sp)
    80005300:	6145                	addi	sp,sp,48
    80005302:	8082                	ret
    return -1;
    80005304:	557d                	li	a0,-1
    80005306:	bfcd                	j	800052f8 <argfd+0x50>
    return -1;
    80005308:	557d                	li	a0,-1
    8000530a:	b7fd                	j	800052f8 <argfd+0x50>
    8000530c:	557d                	li	a0,-1
    8000530e:	b7ed                	j	800052f8 <argfd+0x50>

0000000080005310 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005310:	1101                	addi	sp,sp,-32
    80005312:	ec06                	sd	ra,24(sp)
    80005314:	e822                	sd	s0,16(sp)
    80005316:	e426                	sd	s1,8(sp)
    80005318:	1000                	addi	s0,sp,32
    8000531a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000531c:	ffffc097          	auipc	ra,0xffffc
    80005320:	676080e7          	jalr	1654(ra) # 80001992 <myproc>
    80005324:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005326:	0e850793          	addi	a5,a0,232
    8000532a:	4501                	li	a0,0
    8000532c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000532e:	6398                	ld	a4,0(a5)
    80005330:	cb19                	beqz	a4,80005346 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005332:	2505                	addiw	a0,a0,1
    80005334:	07a1                	addi	a5,a5,8
    80005336:	fed51ce3          	bne	a0,a3,8000532e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000533a:	557d                	li	a0,-1
}
    8000533c:	60e2                	ld	ra,24(sp)
    8000533e:	6442                	ld	s0,16(sp)
    80005340:	64a2                	ld	s1,8(sp)
    80005342:	6105                	addi	sp,sp,32
    80005344:	8082                	ret
      p->ofile[fd] = f;
    80005346:	01c50793          	addi	a5,a0,28
    8000534a:	078e                	slli	a5,a5,0x3
    8000534c:	963e                	add	a2,a2,a5
    8000534e:	e604                	sd	s1,8(a2)
      return fd;
    80005350:	b7f5                	j	8000533c <fdalloc+0x2c>

0000000080005352 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005352:	715d                	addi	sp,sp,-80
    80005354:	e486                	sd	ra,72(sp)
    80005356:	e0a2                	sd	s0,64(sp)
    80005358:	fc26                	sd	s1,56(sp)
    8000535a:	f84a                	sd	s2,48(sp)
    8000535c:	f44e                	sd	s3,40(sp)
    8000535e:	f052                	sd	s4,32(sp)
    80005360:	ec56                	sd	s5,24(sp)
    80005362:	0880                	addi	s0,sp,80
    80005364:	89ae                	mv	s3,a1
    80005366:	8ab2                	mv	s5,a2
    80005368:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000536a:	fb040593          	addi	a1,s0,-80
    8000536e:	fffff097          	auipc	ra,0xfffff
    80005372:	e72080e7          	jalr	-398(ra) # 800041e0 <nameiparent>
    80005376:	892a                	mv	s2,a0
    80005378:	12050e63          	beqz	a0,800054b4 <create+0x162>
    return 0;

  ilock(dp);
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	690080e7          	jalr	1680(ra) # 80003a0c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005384:	4601                	li	a2,0
    80005386:	fb040593          	addi	a1,s0,-80
    8000538a:	854a                	mv	a0,s2
    8000538c:	fffff097          	auipc	ra,0xfffff
    80005390:	b64080e7          	jalr	-1180(ra) # 80003ef0 <dirlookup>
    80005394:	84aa                	mv	s1,a0
    80005396:	c921                	beqz	a0,800053e6 <create+0x94>
    iunlockput(dp);
    80005398:	854a                	mv	a0,s2
    8000539a:	fffff097          	auipc	ra,0xfffff
    8000539e:	8d4080e7          	jalr	-1836(ra) # 80003c6e <iunlockput>
    ilock(ip);
    800053a2:	8526                	mv	a0,s1
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	668080e7          	jalr	1640(ra) # 80003a0c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053ac:	2981                	sext.w	s3,s3
    800053ae:	4789                	li	a5,2
    800053b0:	02f99463          	bne	s3,a5,800053d8 <create+0x86>
    800053b4:	0444d783          	lhu	a5,68(s1)
    800053b8:	37f9                	addiw	a5,a5,-2
    800053ba:	17c2                	slli	a5,a5,0x30
    800053bc:	93c1                	srli	a5,a5,0x30
    800053be:	4705                	li	a4,1
    800053c0:	00f76c63          	bltu	a4,a5,800053d8 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053c4:	8526                	mv	a0,s1
    800053c6:	60a6                	ld	ra,72(sp)
    800053c8:	6406                	ld	s0,64(sp)
    800053ca:	74e2                	ld	s1,56(sp)
    800053cc:	7942                	ld	s2,48(sp)
    800053ce:	79a2                	ld	s3,40(sp)
    800053d0:	7a02                	ld	s4,32(sp)
    800053d2:	6ae2                	ld	s5,24(sp)
    800053d4:	6161                	addi	sp,sp,80
    800053d6:	8082                	ret
    iunlockput(ip);
    800053d8:	8526                	mv	a0,s1
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	894080e7          	jalr	-1900(ra) # 80003c6e <iunlockput>
    return 0;
    800053e2:	4481                	li	s1,0
    800053e4:	b7c5                	j	800053c4 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053e6:	85ce                	mv	a1,s3
    800053e8:	00092503          	lw	a0,0(s2)
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	488080e7          	jalr	1160(ra) # 80003874 <ialloc>
    800053f4:	84aa                	mv	s1,a0
    800053f6:	c521                	beqz	a0,8000543e <create+0xec>
  ilock(ip);
    800053f8:	ffffe097          	auipc	ra,0xffffe
    800053fc:	614080e7          	jalr	1556(ra) # 80003a0c <ilock>
  ip->major = major;
    80005400:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005404:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005408:	4a05                	li	s4,1
    8000540a:	05449523          	sh	s4,74(s1)
  iupdate(ip);
    8000540e:	8526                	mv	a0,s1
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	532080e7          	jalr	1330(ra) # 80003942 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005418:	2981                	sext.w	s3,s3
    8000541a:	03498a63          	beq	s3,s4,8000544e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000541e:	40d0                	lw	a2,4(s1)
    80005420:	fb040593          	addi	a1,s0,-80
    80005424:	854a                	mv	a0,s2
    80005426:	fffff097          	auipc	ra,0xfffff
    8000542a:	cda080e7          	jalr	-806(ra) # 80004100 <dirlink>
    8000542e:	06054b63          	bltz	a0,800054a4 <create+0x152>
  iunlockput(dp);
    80005432:	854a                	mv	a0,s2
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	83a080e7          	jalr	-1990(ra) # 80003c6e <iunlockput>
  return ip;
    8000543c:	b761                	j	800053c4 <create+0x72>
    panic("create: ialloc");
    8000543e:	00003517          	auipc	a0,0x3
    80005442:	5aa50513          	addi	a0,a0,1450 # 800089e8 <syscalls_str+0x2b0>
    80005446:	ffffb097          	auipc	ra,0xffffb
    8000544a:	0e4080e7          	jalr	228(ra) # 8000052a <panic>
    dp->nlink++;  // for ".."
    8000544e:	04a95783          	lhu	a5,74(s2)
    80005452:	2785                	addiw	a5,a5,1
    80005454:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005458:	854a                	mv	a0,s2
    8000545a:	ffffe097          	auipc	ra,0xffffe
    8000545e:	4e8080e7          	jalr	1256(ra) # 80003942 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005462:	40d0                	lw	a2,4(s1)
    80005464:	00003597          	auipc	a1,0x3
    80005468:	59458593          	addi	a1,a1,1428 # 800089f8 <syscalls_str+0x2c0>
    8000546c:	8526                	mv	a0,s1
    8000546e:	fffff097          	auipc	ra,0xfffff
    80005472:	c92080e7          	jalr	-878(ra) # 80004100 <dirlink>
    80005476:	00054f63          	bltz	a0,80005494 <create+0x142>
    8000547a:	00492603          	lw	a2,4(s2)
    8000547e:	00003597          	auipc	a1,0x3
    80005482:	58258593          	addi	a1,a1,1410 # 80008a00 <syscalls_str+0x2c8>
    80005486:	8526                	mv	a0,s1
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	c78080e7          	jalr	-904(ra) # 80004100 <dirlink>
    80005490:	f80557e3          	bgez	a0,8000541e <create+0xcc>
      panic("create dots");
    80005494:	00003517          	auipc	a0,0x3
    80005498:	57450513          	addi	a0,a0,1396 # 80008a08 <syscalls_str+0x2d0>
    8000549c:	ffffb097          	auipc	ra,0xffffb
    800054a0:	08e080e7          	jalr	142(ra) # 8000052a <panic>
    panic("create: dirlink");
    800054a4:	00003517          	auipc	a0,0x3
    800054a8:	57450513          	addi	a0,a0,1396 # 80008a18 <syscalls_str+0x2e0>
    800054ac:	ffffb097          	auipc	ra,0xffffb
    800054b0:	07e080e7          	jalr	126(ra) # 8000052a <panic>
    return 0;
    800054b4:	84aa                	mv	s1,a0
    800054b6:	b739                	j	800053c4 <create+0x72>

00000000800054b8 <sys_dup>:
{
    800054b8:	7179                	addi	sp,sp,-48
    800054ba:	f406                	sd	ra,40(sp)
    800054bc:	f022                	sd	s0,32(sp)
    800054be:	ec26                	sd	s1,24(sp)
    800054c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054c2:	fd840613          	addi	a2,s0,-40
    800054c6:	4581                	li	a1,0
    800054c8:	4501                	li	a0,0
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	dde080e7          	jalr	-546(ra) # 800052a8 <argfd>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054d4:	02054363          	bltz	a0,800054fa <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054d8:	fd843503          	ld	a0,-40(s0)
    800054dc:	00000097          	auipc	ra,0x0
    800054e0:	e34080e7          	jalr	-460(ra) # 80005310 <fdalloc>
    800054e4:	84aa                	mv	s1,a0
    return -1;
    800054e6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054e8:	00054963          	bltz	a0,800054fa <sys_dup+0x42>
  filedup(f);
    800054ec:	fd843503          	ld	a0,-40(s0)
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	36c080e7          	jalr	876(ra) # 8000485c <filedup>
  return fd;
    800054f8:	87a6                	mv	a5,s1
}
    800054fa:	853e                	mv	a0,a5
    800054fc:	70a2                	ld	ra,40(sp)
    800054fe:	7402                	ld	s0,32(sp)
    80005500:	64e2                	ld	s1,24(sp)
    80005502:	6145                	addi	sp,sp,48
    80005504:	8082                	ret

0000000080005506 <sys_read>:
{
    80005506:	7179                	addi	sp,sp,-48
    80005508:	f406                	sd	ra,40(sp)
    8000550a:	f022                	sd	s0,32(sp)
    8000550c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550e:	fe840613          	addi	a2,s0,-24
    80005512:	4581                	li	a1,0
    80005514:	4501                	li	a0,0
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	d92080e7          	jalr	-622(ra) # 800052a8 <argfd>
    return -1;
    8000551e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005520:	04054163          	bltz	a0,80005562 <sys_read+0x5c>
    80005524:	fe440593          	addi	a1,s0,-28
    80005528:	4509                	li	a0,2
    8000552a:	ffffe097          	auipc	ra,0xffffe
    8000552e:	83e080e7          	jalr	-1986(ra) # 80002d68 <argint>
    return -1;
    80005532:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005534:	02054763          	bltz	a0,80005562 <sys_read+0x5c>
    80005538:	fd840593          	addi	a1,s0,-40
    8000553c:	4505                	li	a0,1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	84c080e7          	jalr	-1972(ra) # 80002d8a <argaddr>
    return -1;
    80005546:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005548:	00054d63          	bltz	a0,80005562 <sys_read+0x5c>
  return fileread(f, p, n);
    8000554c:	fe442603          	lw	a2,-28(s0)
    80005550:	fd843583          	ld	a1,-40(s0)
    80005554:	fe843503          	ld	a0,-24(s0)
    80005558:	fffff097          	auipc	ra,0xfffff
    8000555c:	490080e7          	jalr	1168(ra) # 800049e8 <fileread>
    80005560:	87aa                	mv	a5,a0
}
    80005562:	853e                	mv	a0,a5
    80005564:	70a2                	ld	ra,40(sp)
    80005566:	7402                	ld	s0,32(sp)
    80005568:	6145                	addi	sp,sp,48
    8000556a:	8082                	ret

000000008000556c <sys_write>:
{
    8000556c:	7179                	addi	sp,sp,-48
    8000556e:	f406                	sd	ra,40(sp)
    80005570:	f022                	sd	s0,32(sp)
    80005572:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005574:	fe840613          	addi	a2,s0,-24
    80005578:	4581                	li	a1,0
    8000557a:	4501                	li	a0,0
    8000557c:	00000097          	auipc	ra,0x0
    80005580:	d2c080e7          	jalr	-724(ra) # 800052a8 <argfd>
    return -1;
    80005584:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005586:	04054163          	bltz	a0,800055c8 <sys_write+0x5c>
    8000558a:	fe440593          	addi	a1,s0,-28
    8000558e:	4509                	li	a0,2
    80005590:	ffffd097          	auipc	ra,0xffffd
    80005594:	7d8080e7          	jalr	2008(ra) # 80002d68 <argint>
    return -1;
    80005598:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000559a:	02054763          	bltz	a0,800055c8 <sys_write+0x5c>
    8000559e:	fd840593          	addi	a1,s0,-40
    800055a2:	4505                	li	a0,1
    800055a4:	ffffd097          	auipc	ra,0xffffd
    800055a8:	7e6080e7          	jalr	2022(ra) # 80002d8a <argaddr>
    return -1;
    800055ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055ae:	00054d63          	bltz	a0,800055c8 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055b2:	fe442603          	lw	a2,-28(s0)
    800055b6:	fd843583          	ld	a1,-40(s0)
    800055ba:	fe843503          	ld	a0,-24(s0)
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	4ec080e7          	jalr	1260(ra) # 80004aaa <filewrite>
    800055c6:	87aa                	mv	a5,a0
}
    800055c8:	853e                	mv	a0,a5
    800055ca:	70a2                	ld	ra,40(sp)
    800055cc:	7402                	ld	s0,32(sp)
    800055ce:	6145                	addi	sp,sp,48
    800055d0:	8082                	ret

00000000800055d2 <sys_close>:
{
    800055d2:	1101                	addi	sp,sp,-32
    800055d4:	ec06                	sd	ra,24(sp)
    800055d6:	e822                	sd	s0,16(sp)
    800055d8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055da:	fe040613          	addi	a2,s0,-32
    800055de:	fec40593          	addi	a1,s0,-20
    800055e2:	4501                	li	a0,0
    800055e4:	00000097          	auipc	ra,0x0
    800055e8:	cc4080e7          	jalr	-828(ra) # 800052a8 <argfd>
    return -1;
    800055ec:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055ee:	02054463          	bltz	a0,80005616 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055f2:	ffffc097          	auipc	ra,0xffffc
    800055f6:	3a0080e7          	jalr	928(ra) # 80001992 <myproc>
    800055fa:	fec42783          	lw	a5,-20(s0)
    800055fe:	07f1                	addi	a5,a5,28
    80005600:	078e                	slli	a5,a5,0x3
    80005602:	97aa                	add	a5,a5,a0
    80005604:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005608:	fe043503          	ld	a0,-32(s0)
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	2a2080e7          	jalr	674(ra) # 800048ae <fileclose>
  return 0;
    80005614:	4781                	li	a5,0
}
    80005616:	853e                	mv	a0,a5
    80005618:	60e2                	ld	ra,24(sp)
    8000561a:	6442                	ld	s0,16(sp)
    8000561c:	6105                	addi	sp,sp,32
    8000561e:	8082                	ret

0000000080005620 <sys_fstat>:
{
    80005620:	1101                	addi	sp,sp,-32
    80005622:	ec06                	sd	ra,24(sp)
    80005624:	e822                	sd	s0,16(sp)
    80005626:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005628:	fe840613          	addi	a2,s0,-24
    8000562c:	4581                	li	a1,0
    8000562e:	4501                	li	a0,0
    80005630:	00000097          	auipc	ra,0x0
    80005634:	c78080e7          	jalr	-904(ra) # 800052a8 <argfd>
    return -1;
    80005638:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000563a:	02054563          	bltz	a0,80005664 <sys_fstat+0x44>
    8000563e:	fe040593          	addi	a1,s0,-32
    80005642:	4505                	li	a0,1
    80005644:	ffffd097          	auipc	ra,0xffffd
    80005648:	746080e7          	jalr	1862(ra) # 80002d8a <argaddr>
    return -1;
    8000564c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000564e:	00054b63          	bltz	a0,80005664 <sys_fstat+0x44>
  return filestat(f, st);
    80005652:	fe043583          	ld	a1,-32(s0)
    80005656:	fe843503          	ld	a0,-24(s0)
    8000565a:	fffff097          	auipc	ra,0xfffff
    8000565e:	31c080e7          	jalr	796(ra) # 80004976 <filestat>
    80005662:	87aa                	mv	a5,a0
}
    80005664:	853e                	mv	a0,a5
    80005666:	60e2                	ld	ra,24(sp)
    80005668:	6442                	ld	s0,16(sp)
    8000566a:	6105                	addi	sp,sp,32
    8000566c:	8082                	ret

000000008000566e <sys_link>:
{
    8000566e:	7169                	addi	sp,sp,-304
    80005670:	f606                	sd	ra,296(sp)
    80005672:	f222                	sd	s0,288(sp)
    80005674:	ee26                	sd	s1,280(sp)
    80005676:	ea4a                	sd	s2,272(sp)
    80005678:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000567a:	08000613          	li	a2,128
    8000567e:	ed040593          	addi	a1,s0,-304
    80005682:	4501                	li	a0,0
    80005684:	ffffd097          	auipc	ra,0xffffd
    80005688:	728080e7          	jalr	1832(ra) # 80002dac <argstr>
    return -1;
    8000568c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000568e:	10054e63          	bltz	a0,800057aa <sys_link+0x13c>
    80005692:	08000613          	li	a2,128
    80005696:	f5040593          	addi	a1,s0,-176
    8000569a:	4505                	li	a0,1
    8000569c:	ffffd097          	auipc	ra,0xffffd
    800056a0:	710080e7          	jalr	1808(ra) # 80002dac <argstr>
    return -1;
    800056a4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a6:	10054263          	bltz	a0,800057aa <sys_link+0x13c>
  begin_op();
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	d38080e7          	jalr	-712(ra) # 800043e2 <begin_op>
  if((ip = namei(old)) == 0){
    800056b2:	ed040513          	addi	a0,s0,-304
    800056b6:	fffff097          	auipc	ra,0xfffff
    800056ba:	b0c080e7          	jalr	-1268(ra) # 800041c2 <namei>
    800056be:	84aa                	mv	s1,a0
    800056c0:	c551                	beqz	a0,8000574c <sys_link+0xde>
  ilock(ip);
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	34a080e7          	jalr	842(ra) # 80003a0c <ilock>
  if(ip->type == T_DIR){
    800056ca:	04449703          	lh	a4,68(s1)
    800056ce:	4785                	li	a5,1
    800056d0:	08f70463          	beq	a4,a5,80005758 <sys_link+0xea>
  ip->nlink++;
    800056d4:	04a4d783          	lhu	a5,74(s1)
    800056d8:	2785                	addiw	a5,a5,1
    800056da:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056de:	8526                	mv	a0,s1
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	262080e7          	jalr	610(ra) # 80003942 <iupdate>
  iunlock(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	3e4080e7          	jalr	996(ra) # 80003ace <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056f2:	fd040593          	addi	a1,s0,-48
    800056f6:	f5040513          	addi	a0,s0,-176
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	ae6080e7          	jalr	-1306(ra) # 800041e0 <nameiparent>
    80005702:	892a                	mv	s2,a0
    80005704:	c935                	beqz	a0,80005778 <sys_link+0x10a>
  ilock(dp);
    80005706:	ffffe097          	auipc	ra,0xffffe
    8000570a:	306080e7          	jalr	774(ra) # 80003a0c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000570e:	00092703          	lw	a4,0(s2)
    80005712:	409c                	lw	a5,0(s1)
    80005714:	04f71d63          	bne	a4,a5,8000576e <sys_link+0x100>
    80005718:	40d0                	lw	a2,4(s1)
    8000571a:	fd040593          	addi	a1,s0,-48
    8000571e:	854a                	mv	a0,s2
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	9e0080e7          	jalr	-1568(ra) # 80004100 <dirlink>
    80005728:	04054363          	bltz	a0,8000576e <sys_link+0x100>
  iunlockput(dp);
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	540080e7          	jalr	1344(ra) # 80003c6e <iunlockput>
  iput(ip);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	48e080e7          	jalr	1166(ra) # 80003bc6 <iput>
  end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	d22080e7          	jalr	-734(ra) # 80004462 <end_op>
  return 0;
    80005748:	4781                	li	a5,0
    8000574a:	a085                	j	800057aa <sys_link+0x13c>
    end_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	d16080e7          	jalr	-746(ra) # 80004462 <end_op>
    return -1;
    80005754:	57fd                	li	a5,-1
    80005756:	a891                	j	800057aa <sys_link+0x13c>
    iunlockput(ip);
    80005758:	8526                	mv	a0,s1
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	514080e7          	jalr	1300(ra) # 80003c6e <iunlockput>
    end_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	d00080e7          	jalr	-768(ra) # 80004462 <end_op>
    return -1;
    8000576a:	57fd                	li	a5,-1
    8000576c:	a83d                	j	800057aa <sys_link+0x13c>
    iunlockput(dp);
    8000576e:	854a                	mv	a0,s2
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	4fe080e7          	jalr	1278(ra) # 80003c6e <iunlockput>
  ilock(ip);
    80005778:	8526                	mv	a0,s1
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	292080e7          	jalr	658(ra) # 80003a0c <ilock>
  ip->nlink--;
    80005782:	04a4d783          	lhu	a5,74(s1)
    80005786:	37fd                	addiw	a5,a5,-1
    80005788:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000578c:	8526                	mv	a0,s1
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	1b4080e7          	jalr	436(ra) # 80003942 <iupdate>
  iunlockput(ip);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	4d6080e7          	jalr	1238(ra) # 80003c6e <iunlockput>
  end_op();
    800057a0:	fffff097          	auipc	ra,0xfffff
    800057a4:	cc2080e7          	jalr	-830(ra) # 80004462 <end_op>
  return -1;
    800057a8:	57fd                	li	a5,-1
}
    800057aa:	853e                	mv	a0,a5
    800057ac:	70b2                	ld	ra,296(sp)
    800057ae:	7412                	ld	s0,288(sp)
    800057b0:	64f2                	ld	s1,280(sp)
    800057b2:	6952                	ld	s2,272(sp)
    800057b4:	6155                	addi	sp,sp,304
    800057b6:	8082                	ret

00000000800057b8 <sys_unlink>:
{
    800057b8:	7151                	addi	sp,sp,-240
    800057ba:	f586                	sd	ra,232(sp)
    800057bc:	f1a2                	sd	s0,224(sp)
    800057be:	eda6                	sd	s1,216(sp)
    800057c0:	e9ca                	sd	s2,208(sp)
    800057c2:	e5ce                	sd	s3,200(sp)
    800057c4:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057c6:	08000613          	li	a2,128
    800057ca:	f3040593          	addi	a1,s0,-208
    800057ce:	4501                	li	a0,0
    800057d0:	ffffd097          	auipc	ra,0xffffd
    800057d4:	5dc080e7          	jalr	1500(ra) # 80002dac <argstr>
    800057d8:	18054163          	bltz	a0,8000595a <sys_unlink+0x1a2>
  begin_op();
    800057dc:	fffff097          	auipc	ra,0xfffff
    800057e0:	c06080e7          	jalr	-1018(ra) # 800043e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057e4:	fb040593          	addi	a1,s0,-80
    800057e8:	f3040513          	addi	a0,s0,-208
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	9f4080e7          	jalr	-1548(ra) # 800041e0 <nameiparent>
    800057f4:	84aa                	mv	s1,a0
    800057f6:	c979                	beqz	a0,800058cc <sys_unlink+0x114>
  ilock(dp);
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	214080e7          	jalr	532(ra) # 80003a0c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005800:	00003597          	auipc	a1,0x3
    80005804:	1f858593          	addi	a1,a1,504 # 800089f8 <syscalls_str+0x2c0>
    80005808:	fb040513          	addi	a0,s0,-80
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	6ca080e7          	jalr	1738(ra) # 80003ed6 <namecmp>
    80005814:	14050a63          	beqz	a0,80005968 <sys_unlink+0x1b0>
    80005818:	00003597          	auipc	a1,0x3
    8000581c:	1e858593          	addi	a1,a1,488 # 80008a00 <syscalls_str+0x2c8>
    80005820:	fb040513          	addi	a0,s0,-80
    80005824:	ffffe097          	auipc	ra,0xffffe
    80005828:	6b2080e7          	jalr	1714(ra) # 80003ed6 <namecmp>
    8000582c:	12050e63          	beqz	a0,80005968 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005830:	f2c40613          	addi	a2,s0,-212
    80005834:	fb040593          	addi	a1,s0,-80
    80005838:	8526                	mv	a0,s1
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	6b6080e7          	jalr	1718(ra) # 80003ef0 <dirlookup>
    80005842:	892a                	mv	s2,a0
    80005844:	12050263          	beqz	a0,80005968 <sys_unlink+0x1b0>
  ilock(ip);
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	1c4080e7          	jalr	452(ra) # 80003a0c <ilock>
  if(ip->nlink < 1)
    80005850:	04a91783          	lh	a5,74(s2)
    80005854:	08f05263          	blez	a5,800058d8 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005858:	04491703          	lh	a4,68(s2)
    8000585c:	4785                	li	a5,1
    8000585e:	08f70563          	beq	a4,a5,800058e8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005862:	4641                	li	a2,16
    80005864:	4581                	li	a1,0
    80005866:	fc040513          	addi	a0,s0,-64
    8000586a:	ffffb097          	auipc	ra,0xffffb
    8000586e:	454080e7          	jalr	1108(ra) # 80000cbe <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005872:	4741                	li	a4,16
    80005874:	f2c42683          	lw	a3,-212(s0)
    80005878:	fc040613          	addi	a2,s0,-64
    8000587c:	4581                	li	a1,0
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	538080e7          	jalr	1336(ra) # 80003db8 <writei>
    80005888:	47c1                	li	a5,16
    8000588a:	0af51563          	bne	a0,a5,80005934 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000588e:	04491703          	lh	a4,68(s2)
    80005892:	4785                	li	a5,1
    80005894:	0af70863          	beq	a4,a5,80005944 <sys_unlink+0x18c>
  iunlockput(dp);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	3d4080e7          	jalr	980(ra) # 80003c6e <iunlockput>
  ip->nlink--;
    800058a2:	04a95783          	lhu	a5,74(s2)
    800058a6:	37fd                	addiw	a5,a5,-1
    800058a8:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	094080e7          	jalr	148(ra) # 80003942 <iupdate>
  iunlockput(ip);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	3b6080e7          	jalr	950(ra) # 80003c6e <iunlockput>
  end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	ba2080e7          	jalr	-1118(ra) # 80004462 <end_op>
  return 0;
    800058c8:	4501                	li	a0,0
    800058ca:	a84d                	j	8000597c <sys_unlink+0x1c4>
    end_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	b96080e7          	jalr	-1130(ra) # 80004462 <end_op>
    return -1;
    800058d4:	557d                	li	a0,-1
    800058d6:	a05d                	j	8000597c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058d8:	00003517          	auipc	a0,0x3
    800058dc:	15050513          	addi	a0,a0,336 # 80008a28 <syscalls_str+0x2f0>
    800058e0:	ffffb097          	auipc	ra,0xffffb
    800058e4:	c4a080e7          	jalr	-950(ra) # 8000052a <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058e8:	04c92703          	lw	a4,76(s2)
    800058ec:	02000793          	li	a5,32
    800058f0:	f6e7f9e3          	bgeu	a5,a4,80005862 <sys_unlink+0xaa>
    800058f4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058f8:	4741                	li	a4,16
    800058fa:	86ce                	mv	a3,s3
    800058fc:	f1840613          	addi	a2,s0,-232
    80005900:	4581                	li	a1,0
    80005902:	854a                	mv	a0,s2
    80005904:	ffffe097          	auipc	ra,0xffffe
    80005908:	3bc080e7          	jalr	956(ra) # 80003cc0 <readi>
    8000590c:	47c1                	li	a5,16
    8000590e:	00f51b63          	bne	a0,a5,80005924 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005912:	f1845783          	lhu	a5,-232(s0)
    80005916:	e7a1                	bnez	a5,8000595e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005918:	29c1                	addiw	s3,s3,16
    8000591a:	04c92783          	lw	a5,76(s2)
    8000591e:	fcf9ede3          	bltu	s3,a5,800058f8 <sys_unlink+0x140>
    80005922:	b781                	j	80005862 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005924:	00003517          	auipc	a0,0x3
    80005928:	11c50513          	addi	a0,a0,284 # 80008a40 <syscalls_str+0x308>
    8000592c:	ffffb097          	auipc	ra,0xffffb
    80005930:	bfe080e7          	jalr	-1026(ra) # 8000052a <panic>
    panic("unlink: writei");
    80005934:	00003517          	auipc	a0,0x3
    80005938:	12450513          	addi	a0,a0,292 # 80008a58 <syscalls_str+0x320>
    8000593c:	ffffb097          	auipc	ra,0xffffb
    80005940:	bee080e7          	jalr	-1042(ra) # 8000052a <panic>
    dp->nlink--;
    80005944:	04a4d783          	lhu	a5,74(s1)
    80005948:	37fd                	addiw	a5,a5,-1
    8000594a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	ff2080e7          	jalr	-14(ra) # 80003942 <iupdate>
    80005958:	b781                	j	80005898 <sys_unlink+0xe0>
    return -1;
    8000595a:	557d                	li	a0,-1
    8000595c:	a005                	j	8000597c <sys_unlink+0x1c4>
    iunlockput(ip);
    8000595e:	854a                	mv	a0,s2
    80005960:	ffffe097          	auipc	ra,0xffffe
    80005964:	30e080e7          	jalr	782(ra) # 80003c6e <iunlockput>
  iunlockput(dp);
    80005968:	8526                	mv	a0,s1
    8000596a:	ffffe097          	auipc	ra,0xffffe
    8000596e:	304080e7          	jalr	772(ra) # 80003c6e <iunlockput>
  end_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	af0080e7          	jalr	-1296(ra) # 80004462 <end_op>
  return -1;
    8000597a:	557d                	li	a0,-1
}
    8000597c:	70ae                	ld	ra,232(sp)
    8000597e:	740e                	ld	s0,224(sp)
    80005980:	64ee                	ld	s1,216(sp)
    80005982:	694e                	ld	s2,208(sp)
    80005984:	69ae                	ld	s3,200(sp)
    80005986:	616d                	addi	sp,sp,240
    80005988:	8082                	ret

000000008000598a <sys_open>:

uint64
sys_open(void)
{
    8000598a:	7131                	addi	sp,sp,-192
    8000598c:	fd06                	sd	ra,184(sp)
    8000598e:	f922                	sd	s0,176(sp)
    80005990:	f526                	sd	s1,168(sp)
    80005992:	f14a                	sd	s2,160(sp)
    80005994:	ed4e                	sd	s3,152(sp)
    80005996:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005998:	08000613          	li	a2,128
    8000599c:	f5040593          	addi	a1,s0,-176
    800059a0:	4501                	li	a0,0
    800059a2:	ffffd097          	auipc	ra,0xffffd
    800059a6:	40a080e7          	jalr	1034(ra) # 80002dac <argstr>
    return -1;
    800059aa:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059ac:	0c054163          	bltz	a0,80005a6e <sys_open+0xe4>
    800059b0:	f4c40593          	addi	a1,s0,-180
    800059b4:	4505                	li	a0,1
    800059b6:	ffffd097          	auipc	ra,0xffffd
    800059ba:	3b2080e7          	jalr	946(ra) # 80002d68 <argint>
    800059be:	0a054863          	bltz	a0,80005a6e <sys_open+0xe4>

  begin_op();
    800059c2:	fffff097          	auipc	ra,0xfffff
    800059c6:	a20080e7          	jalr	-1504(ra) # 800043e2 <begin_op>

  if(omode & O_CREATE){
    800059ca:	f4c42783          	lw	a5,-180(s0)
    800059ce:	2007f793          	andi	a5,a5,512
    800059d2:	cbdd                	beqz	a5,80005a88 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059d4:	4681                	li	a3,0
    800059d6:	4601                	li	a2,0
    800059d8:	4589                	li	a1,2
    800059da:	f5040513          	addi	a0,s0,-176
    800059de:	00000097          	auipc	ra,0x0
    800059e2:	974080e7          	jalr	-1676(ra) # 80005352 <create>
    800059e6:	892a                	mv	s2,a0
    if(ip == 0){
    800059e8:	c959                	beqz	a0,80005a7e <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059ea:	04491703          	lh	a4,68(s2)
    800059ee:	478d                	li	a5,3
    800059f0:	00f71763          	bne	a4,a5,800059fe <sys_open+0x74>
    800059f4:	04695703          	lhu	a4,70(s2)
    800059f8:	47a5                	li	a5,9
    800059fa:	0ce7ec63          	bltu	a5,a4,80005ad2 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	df4080e7          	jalr	-524(ra) # 800047f2 <filealloc>
    80005a06:	89aa                	mv	s3,a0
    80005a08:	10050263          	beqz	a0,80005b0c <sys_open+0x182>
    80005a0c:	00000097          	auipc	ra,0x0
    80005a10:	904080e7          	jalr	-1788(ra) # 80005310 <fdalloc>
    80005a14:	84aa                	mv	s1,a0
    80005a16:	0e054663          	bltz	a0,80005b02 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a1a:	04491703          	lh	a4,68(s2)
    80005a1e:	478d                	li	a5,3
    80005a20:	0cf70463          	beq	a4,a5,80005ae8 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a24:	4789                	li	a5,2
    80005a26:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a2a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a2e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a32:	f4c42783          	lw	a5,-180(s0)
    80005a36:	0017c713          	xori	a4,a5,1
    80005a3a:	8b05                	andi	a4,a4,1
    80005a3c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a40:	0037f713          	andi	a4,a5,3
    80005a44:	00e03733          	snez	a4,a4
    80005a48:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a4c:	4007f793          	andi	a5,a5,1024
    80005a50:	c791                	beqz	a5,80005a5c <sys_open+0xd2>
    80005a52:	04491703          	lh	a4,68(s2)
    80005a56:	4789                	li	a5,2
    80005a58:	08f70f63          	beq	a4,a5,80005af6 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a5c:	854a                	mv	a0,s2
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	070080e7          	jalr	112(ra) # 80003ace <iunlock>
  end_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	9fc080e7          	jalr	-1540(ra) # 80004462 <end_op>

  return fd;
}
    80005a6e:	8526                	mv	a0,s1
    80005a70:	70ea                	ld	ra,184(sp)
    80005a72:	744a                	ld	s0,176(sp)
    80005a74:	74aa                	ld	s1,168(sp)
    80005a76:	790a                	ld	s2,160(sp)
    80005a78:	69ea                	ld	s3,152(sp)
    80005a7a:	6129                	addi	sp,sp,192
    80005a7c:	8082                	ret
      end_op();
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	9e4080e7          	jalr	-1564(ra) # 80004462 <end_op>
      return -1;
    80005a86:	b7e5                	j	80005a6e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a88:	f5040513          	addi	a0,s0,-176
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	736080e7          	jalr	1846(ra) # 800041c2 <namei>
    80005a94:	892a                	mv	s2,a0
    80005a96:	c905                	beqz	a0,80005ac6 <sys_open+0x13c>
    ilock(ip);
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	f74080e7          	jalr	-140(ra) # 80003a0c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005aa0:	04491703          	lh	a4,68(s2)
    80005aa4:	4785                	li	a5,1
    80005aa6:	f4f712e3          	bne	a4,a5,800059ea <sys_open+0x60>
    80005aaa:	f4c42783          	lw	a5,-180(s0)
    80005aae:	dba1                	beqz	a5,800059fe <sys_open+0x74>
      iunlockput(ip);
    80005ab0:	854a                	mv	a0,s2
    80005ab2:	ffffe097          	auipc	ra,0xffffe
    80005ab6:	1bc080e7          	jalr	444(ra) # 80003c6e <iunlockput>
      end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	9a8080e7          	jalr	-1624(ra) # 80004462 <end_op>
      return -1;
    80005ac2:	54fd                	li	s1,-1
    80005ac4:	b76d                	j	80005a6e <sys_open+0xe4>
      end_op();
    80005ac6:	fffff097          	auipc	ra,0xfffff
    80005aca:	99c080e7          	jalr	-1636(ra) # 80004462 <end_op>
      return -1;
    80005ace:	54fd                	li	s1,-1
    80005ad0:	bf79                	j	80005a6e <sys_open+0xe4>
    iunlockput(ip);
    80005ad2:	854a                	mv	a0,s2
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	19a080e7          	jalr	410(ra) # 80003c6e <iunlockput>
    end_op();
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	986080e7          	jalr	-1658(ra) # 80004462 <end_op>
    return -1;
    80005ae4:	54fd                	li	s1,-1
    80005ae6:	b761                	j	80005a6e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ae8:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005aec:	04691783          	lh	a5,70(s2)
    80005af0:	02f99223          	sh	a5,36(s3)
    80005af4:	bf2d                	j	80005a2e <sys_open+0xa4>
    itrunc(ip);
    80005af6:	854a                	mv	a0,s2
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	022080e7          	jalr	34(ra) # 80003b1a <itrunc>
    80005b00:	bfb1                	j	80005a5c <sys_open+0xd2>
      fileclose(f);
    80005b02:	854e                	mv	a0,s3
    80005b04:	fffff097          	auipc	ra,0xfffff
    80005b08:	daa080e7          	jalr	-598(ra) # 800048ae <fileclose>
    iunlockput(ip);
    80005b0c:	854a                	mv	a0,s2
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	160080e7          	jalr	352(ra) # 80003c6e <iunlockput>
    end_op();
    80005b16:	fffff097          	auipc	ra,0xfffff
    80005b1a:	94c080e7          	jalr	-1716(ra) # 80004462 <end_op>
    return -1;
    80005b1e:	54fd                	li	s1,-1
    80005b20:	b7b9                	j	80005a6e <sys_open+0xe4>

0000000080005b22 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b22:	7175                	addi	sp,sp,-144
    80005b24:	e506                	sd	ra,136(sp)
    80005b26:	e122                	sd	s0,128(sp)
    80005b28:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b2a:	fffff097          	auipc	ra,0xfffff
    80005b2e:	8b8080e7          	jalr	-1864(ra) # 800043e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b32:	08000613          	li	a2,128
    80005b36:	f7040593          	addi	a1,s0,-144
    80005b3a:	4501                	li	a0,0
    80005b3c:	ffffd097          	auipc	ra,0xffffd
    80005b40:	270080e7          	jalr	624(ra) # 80002dac <argstr>
    80005b44:	02054963          	bltz	a0,80005b76 <sys_mkdir+0x54>
    80005b48:	4681                	li	a3,0
    80005b4a:	4601                	li	a2,0
    80005b4c:	4585                	li	a1,1
    80005b4e:	f7040513          	addi	a0,s0,-144
    80005b52:	00000097          	auipc	ra,0x0
    80005b56:	800080e7          	jalr	-2048(ra) # 80005352 <create>
    80005b5a:	cd11                	beqz	a0,80005b76 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	112080e7          	jalr	274(ra) # 80003c6e <iunlockput>
  end_op();
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	8fe080e7          	jalr	-1794(ra) # 80004462 <end_op>
  return 0;
    80005b6c:	4501                	li	a0,0
}
    80005b6e:	60aa                	ld	ra,136(sp)
    80005b70:	640a                	ld	s0,128(sp)
    80005b72:	6149                	addi	sp,sp,144
    80005b74:	8082                	ret
    end_op();
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	8ec080e7          	jalr	-1812(ra) # 80004462 <end_op>
    return -1;
    80005b7e:	557d                	li	a0,-1
    80005b80:	b7fd                	j	80005b6e <sys_mkdir+0x4c>

0000000080005b82 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b82:	7135                	addi	sp,sp,-160
    80005b84:	ed06                	sd	ra,152(sp)
    80005b86:	e922                	sd	s0,144(sp)
    80005b88:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	858080e7          	jalr	-1960(ra) # 800043e2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b92:	08000613          	li	a2,128
    80005b96:	f7040593          	addi	a1,s0,-144
    80005b9a:	4501                	li	a0,0
    80005b9c:	ffffd097          	auipc	ra,0xffffd
    80005ba0:	210080e7          	jalr	528(ra) # 80002dac <argstr>
    80005ba4:	04054a63          	bltz	a0,80005bf8 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005ba8:	f6c40593          	addi	a1,s0,-148
    80005bac:	4505                	li	a0,1
    80005bae:	ffffd097          	auipc	ra,0xffffd
    80005bb2:	1ba080e7          	jalr	442(ra) # 80002d68 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb6:	04054163          	bltz	a0,80005bf8 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bba:	f6840593          	addi	a1,s0,-152
    80005bbe:	4509                	li	a0,2
    80005bc0:	ffffd097          	auipc	ra,0xffffd
    80005bc4:	1a8080e7          	jalr	424(ra) # 80002d68 <argint>
     argint(1, &major) < 0 ||
    80005bc8:	02054863          	bltz	a0,80005bf8 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bcc:	f6841683          	lh	a3,-152(s0)
    80005bd0:	f6c41603          	lh	a2,-148(s0)
    80005bd4:	458d                	li	a1,3
    80005bd6:	f7040513          	addi	a0,s0,-144
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	778080e7          	jalr	1912(ra) # 80005352 <create>
     argint(2, &minor) < 0 ||
    80005be2:	c919                	beqz	a0,80005bf8 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	08a080e7          	jalr	138(ra) # 80003c6e <iunlockput>
  end_op();
    80005bec:	fffff097          	auipc	ra,0xfffff
    80005bf0:	876080e7          	jalr	-1930(ra) # 80004462 <end_op>
  return 0;
    80005bf4:	4501                	li	a0,0
    80005bf6:	a031                	j	80005c02 <sys_mknod+0x80>
    end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	86a080e7          	jalr	-1942(ra) # 80004462 <end_op>
    return -1;
    80005c00:	557d                	li	a0,-1
}
    80005c02:	60ea                	ld	ra,152(sp)
    80005c04:	644a                	ld	s0,144(sp)
    80005c06:	610d                	addi	sp,sp,160
    80005c08:	8082                	ret

0000000080005c0a <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c0a:	7135                	addi	sp,sp,-160
    80005c0c:	ed06                	sd	ra,152(sp)
    80005c0e:	e922                	sd	s0,144(sp)
    80005c10:	e526                	sd	s1,136(sp)
    80005c12:	e14a                	sd	s2,128(sp)
    80005c14:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	d7c080e7          	jalr	-644(ra) # 80001992 <myproc>
    80005c1e:	892a                	mv	s2,a0
  
  begin_op();
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	7c2080e7          	jalr	1986(ra) # 800043e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c28:	08000613          	li	a2,128
    80005c2c:	f6040593          	addi	a1,s0,-160
    80005c30:	4501                	li	a0,0
    80005c32:	ffffd097          	auipc	ra,0xffffd
    80005c36:	17a080e7          	jalr	378(ra) # 80002dac <argstr>
    80005c3a:	04054b63          	bltz	a0,80005c90 <sys_chdir+0x86>
    80005c3e:	f6040513          	addi	a0,s0,-160
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	580080e7          	jalr	1408(ra) # 800041c2 <namei>
    80005c4a:	84aa                	mv	s1,a0
    80005c4c:	c131                	beqz	a0,80005c90 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	dbe080e7          	jalr	-578(ra) # 80003a0c <ilock>
  if(ip->type != T_DIR){
    80005c56:	04449703          	lh	a4,68(s1)
    80005c5a:	4785                	li	a5,1
    80005c5c:	04f71063          	bne	a4,a5,80005c9c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c60:	8526                	mv	a0,s1
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	e6c080e7          	jalr	-404(ra) # 80003ace <iunlock>
  iput(p->cwd);
    80005c6a:	16893503          	ld	a0,360(s2)
    80005c6e:	ffffe097          	auipc	ra,0xffffe
    80005c72:	f58080e7          	jalr	-168(ra) # 80003bc6 <iput>
  end_op();
    80005c76:	ffffe097          	auipc	ra,0xffffe
    80005c7a:	7ec080e7          	jalr	2028(ra) # 80004462 <end_op>
  p->cwd = ip;
    80005c7e:	16993423          	sd	s1,360(s2)
  return 0;
    80005c82:	4501                	li	a0,0
}
    80005c84:	60ea                	ld	ra,152(sp)
    80005c86:	644a                	ld	s0,144(sp)
    80005c88:	64aa                	ld	s1,136(sp)
    80005c8a:	690a                	ld	s2,128(sp)
    80005c8c:	610d                	addi	sp,sp,160
    80005c8e:	8082                	ret
    end_op();
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	7d2080e7          	jalr	2002(ra) # 80004462 <end_op>
    return -1;
    80005c98:	557d                	li	a0,-1
    80005c9a:	b7ed                	j	80005c84 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c9c:	8526                	mv	a0,s1
    80005c9e:	ffffe097          	auipc	ra,0xffffe
    80005ca2:	fd0080e7          	jalr	-48(ra) # 80003c6e <iunlockput>
    end_op();
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	7bc080e7          	jalr	1980(ra) # 80004462 <end_op>
    return -1;
    80005cae:	557d                	li	a0,-1
    80005cb0:	bfd1                	j	80005c84 <sys_chdir+0x7a>

0000000080005cb2 <sys_exec>:

uint64
sys_exec(void)
{
    80005cb2:	7145                	addi	sp,sp,-464
    80005cb4:	e786                	sd	ra,456(sp)
    80005cb6:	e3a2                	sd	s0,448(sp)
    80005cb8:	ff26                	sd	s1,440(sp)
    80005cba:	fb4a                	sd	s2,432(sp)
    80005cbc:	f74e                	sd	s3,424(sp)
    80005cbe:	f352                	sd	s4,416(sp)
    80005cc0:	ef56                	sd	s5,408(sp)
    80005cc2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cc4:	08000613          	li	a2,128
    80005cc8:	f4040593          	addi	a1,s0,-192
    80005ccc:	4501                	li	a0,0
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	0de080e7          	jalr	222(ra) # 80002dac <argstr>
    return -1;
    80005cd6:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cd8:	0c054a63          	bltz	a0,80005dac <sys_exec+0xfa>
    80005cdc:	e3840593          	addi	a1,s0,-456
    80005ce0:	4505                	li	a0,1
    80005ce2:	ffffd097          	auipc	ra,0xffffd
    80005ce6:	0a8080e7          	jalr	168(ra) # 80002d8a <argaddr>
    80005cea:	0c054163          	bltz	a0,80005dac <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cee:	10000613          	li	a2,256
    80005cf2:	4581                	li	a1,0
    80005cf4:	e4040513          	addi	a0,s0,-448
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	fc6080e7          	jalr	-58(ra) # 80000cbe <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d00:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d04:	89a6                	mv	s3,s1
    80005d06:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d08:	02000a13          	li	s4,32
    80005d0c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d10:	00391793          	slli	a5,s2,0x3
    80005d14:	e3040593          	addi	a1,s0,-464
    80005d18:	e3843503          	ld	a0,-456(s0)
    80005d1c:	953e                	add	a0,a0,a5
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	fb0080e7          	jalr	-80(ra) # 80002cce <fetchaddr>
    80005d26:	02054a63          	bltz	a0,80005d5a <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d2a:	e3043783          	ld	a5,-464(s0)
    80005d2e:	c3b9                	beqz	a5,80005d74 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d30:	ffffb097          	auipc	ra,0xffffb
    80005d34:	da2080e7          	jalr	-606(ra) # 80000ad2 <kalloc>
    80005d38:	85aa                	mv	a1,a0
    80005d3a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d3e:	cd11                	beqz	a0,80005d5a <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d40:	6605                	lui	a2,0x1
    80005d42:	e3043503          	ld	a0,-464(s0)
    80005d46:	ffffd097          	auipc	ra,0xffffd
    80005d4a:	fda080e7          	jalr	-38(ra) # 80002d20 <fetchstr>
    80005d4e:	00054663          	bltz	a0,80005d5a <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d52:	0905                	addi	s2,s2,1
    80005d54:	09a1                	addi	s3,s3,8
    80005d56:	fb491be3          	bne	s2,s4,80005d0c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d5a:	10048913          	addi	s2,s1,256
    80005d5e:	6088                	ld	a0,0(s1)
    80005d60:	c529                	beqz	a0,80005daa <sys_exec+0xf8>
    kfree(argv[i]);
    80005d62:	ffffb097          	auipc	ra,0xffffb
    80005d66:	c74080e7          	jalr	-908(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d6a:	04a1                	addi	s1,s1,8
    80005d6c:	ff2499e3          	bne	s1,s2,80005d5e <sys_exec+0xac>
  return -1;
    80005d70:	597d                	li	s2,-1
    80005d72:	a82d                	j	80005dac <sys_exec+0xfa>
      argv[i] = 0;
    80005d74:	0a8e                	slli	s5,s5,0x3
    80005d76:	fc040793          	addi	a5,s0,-64
    80005d7a:	9abe                	add	s5,s5,a5
    80005d7c:	e80ab023          	sd	zero,-384(s5) # ffffffffffffee80 <end+0xffffffff7ffd8e80>
  int ret = exec(path, argv);
    80005d80:	e4040593          	addi	a1,s0,-448
    80005d84:	f4040513          	addi	a0,s0,-192
    80005d88:	fffff097          	auipc	ra,0xfffff
    80005d8c:	178080e7          	jalr	376(ra) # 80004f00 <exec>
    80005d90:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d92:	10048993          	addi	s3,s1,256
    80005d96:	6088                	ld	a0,0(s1)
    80005d98:	c911                	beqz	a0,80005dac <sys_exec+0xfa>
    kfree(argv[i]);
    80005d9a:	ffffb097          	auipc	ra,0xffffb
    80005d9e:	c3c080e7          	jalr	-964(ra) # 800009d6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005da2:	04a1                	addi	s1,s1,8
    80005da4:	ff3499e3          	bne	s1,s3,80005d96 <sys_exec+0xe4>
    80005da8:	a011                	j	80005dac <sys_exec+0xfa>
  return -1;
    80005daa:	597d                	li	s2,-1
}
    80005dac:	854a                	mv	a0,s2
    80005dae:	60be                	ld	ra,456(sp)
    80005db0:	641e                	ld	s0,448(sp)
    80005db2:	74fa                	ld	s1,440(sp)
    80005db4:	795a                	ld	s2,432(sp)
    80005db6:	79ba                	ld	s3,424(sp)
    80005db8:	7a1a                	ld	s4,416(sp)
    80005dba:	6afa                	ld	s5,408(sp)
    80005dbc:	6179                	addi	sp,sp,464
    80005dbe:	8082                	ret

0000000080005dc0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dc0:	7139                	addi	sp,sp,-64
    80005dc2:	fc06                	sd	ra,56(sp)
    80005dc4:	f822                	sd	s0,48(sp)
    80005dc6:	f426                	sd	s1,40(sp)
    80005dc8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dca:	ffffc097          	auipc	ra,0xffffc
    80005dce:	bc8080e7          	jalr	-1080(ra) # 80001992 <myproc>
    80005dd2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005dd4:	fd840593          	addi	a1,s0,-40
    80005dd8:	4501                	li	a0,0
    80005dda:	ffffd097          	auipc	ra,0xffffd
    80005dde:	fb0080e7          	jalr	-80(ra) # 80002d8a <argaddr>
    return -1;
    80005de2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005de4:	0e054063          	bltz	a0,80005ec4 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005de8:	fc840593          	addi	a1,s0,-56
    80005dec:	fd040513          	addi	a0,s0,-48
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	dee080e7          	jalr	-530(ra) # 80004bde <pipealloc>
    return -1;
    80005df8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dfa:	0c054563          	bltz	a0,80005ec4 <sys_pipe+0x104>
  fd0 = -1;
    80005dfe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e02:	fd043503          	ld	a0,-48(s0)
    80005e06:	fffff097          	auipc	ra,0xfffff
    80005e0a:	50a080e7          	jalr	1290(ra) # 80005310 <fdalloc>
    80005e0e:	fca42223          	sw	a0,-60(s0)
    80005e12:	08054c63          	bltz	a0,80005eaa <sys_pipe+0xea>
    80005e16:	fc843503          	ld	a0,-56(s0)
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	4f6080e7          	jalr	1270(ra) # 80005310 <fdalloc>
    80005e22:	fca42023          	sw	a0,-64(s0)
    80005e26:	06054863          	bltz	a0,80005e96 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e2a:	4691                	li	a3,4
    80005e2c:	fc440613          	addi	a2,s0,-60
    80005e30:	fd843583          	ld	a1,-40(s0)
    80005e34:	74a8                	ld	a0,104(s1)
    80005e36:	ffffc097          	auipc	ra,0xffffc
    80005e3a:	808080e7          	jalr	-2040(ra) # 8000163e <copyout>
    80005e3e:	02054063          	bltz	a0,80005e5e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e42:	4691                	li	a3,4
    80005e44:	fc040613          	addi	a2,s0,-64
    80005e48:	fd843583          	ld	a1,-40(s0)
    80005e4c:	0591                	addi	a1,a1,4
    80005e4e:	74a8                	ld	a0,104(s1)
    80005e50:	ffffb097          	auipc	ra,0xffffb
    80005e54:	7ee080e7          	jalr	2030(ra) # 8000163e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e58:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e5a:	06055563          	bgez	a0,80005ec4 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e5e:	fc442783          	lw	a5,-60(s0)
    80005e62:	07f1                	addi	a5,a5,28
    80005e64:	078e                	slli	a5,a5,0x3
    80005e66:	97a6                	add	a5,a5,s1
    80005e68:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e6c:	fc042503          	lw	a0,-64(s0)
    80005e70:	0571                	addi	a0,a0,28
    80005e72:	050e                	slli	a0,a0,0x3
    80005e74:	9526                	add	a0,a0,s1
    80005e76:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e7a:	fd043503          	ld	a0,-48(s0)
    80005e7e:	fffff097          	auipc	ra,0xfffff
    80005e82:	a30080e7          	jalr	-1488(ra) # 800048ae <fileclose>
    fileclose(wf);
    80005e86:	fc843503          	ld	a0,-56(s0)
    80005e8a:	fffff097          	auipc	ra,0xfffff
    80005e8e:	a24080e7          	jalr	-1500(ra) # 800048ae <fileclose>
    return -1;
    80005e92:	57fd                	li	a5,-1
    80005e94:	a805                	j	80005ec4 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005e96:	fc442783          	lw	a5,-60(s0)
    80005e9a:	0007c863          	bltz	a5,80005eaa <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005e9e:	01c78513          	addi	a0,a5,28
    80005ea2:	050e                	slli	a0,a0,0x3
    80005ea4:	9526                	add	a0,a0,s1
    80005ea6:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005eaa:	fd043503          	ld	a0,-48(s0)
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	a00080e7          	jalr	-1536(ra) # 800048ae <fileclose>
    fileclose(wf);
    80005eb6:	fc843503          	ld	a0,-56(s0)
    80005eba:	fffff097          	auipc	ra,0xfffff
    80005ebe:	9f4080e7          	jalr	-1548(ra) # 800048ae <fileclose>
    return -1;
    80005ec2:	57fd                	li	a5,-1
}
    80005ec4:	853e                	mv	a0,a5
    80005ec6:	70e2                	ld	ra,56(sp)
    80005ec8:	7442                	ld	s0,48(sp)
    80005eca:	74a2                	ld	s1,40(sp)
    80005ecc:	6121                	addi	sp,sp,64
    80005ece:	8082                	ret

0000000080005ed0 <kernelvec>:
    80005ed0:	7111                	addi	sp,sp,-256
    80005ed2:	e006                	sd	ra,0(sp)
    80005ed4:	e40a                	sd	sp,8(sp)
    80005ed6:	e80e                	sd	gp,16(sp)
    80005ed8:	ec12                	sd	tp,24(sp)
    80005eda:	f016                	sd	t0,32(sp)
    80005edc:	f41a                	sd	t1,40(sp)
    80005ede:	f81e                	sd	t2,48(sp)
    80005ee0:	fc22                	sd	s0,56(sp)
    80005ee2:	e0a6                	sd	s1,64(sp)
    80005ee4:	e4aa                	sd	a0,72(sp)
    80005ee6:	e8ae                	sd	a1,80(sp)
    80005ee8:	ecb2                	sd	a2,88(sp)
    80005eea:	f0b6                	sd	a3,96(sp)
    80005eec:	f4ba                	sd	a4,104(sp)
    80005eee:	f8be                	sd	a5,112(sp)
    80005ef0:	fcc2                	sd	a6,120(sp)
    80005ef2:	e146                	sd	a7,128(sp)
    80005ef4:	e54a                	sd	s2,136(sp)
    80005ef6:	e94e                	sd	s3,144(sp)
    80005ef8:	ed52                	sd	s4,152(sp)
    80005efa:	f156                	sd	s5,160(sp)
    80005efc:	f55a                	sd	s6,168(sp)
    80005efe:	f95e                	sd	s7,176(sp)
    80005f00:	fd62                	sd	s8,184(sp)
    80005f02:	e1e6                	sd	s9,192(sp)
    80005f04:	e5ea                	sd	s10,200(sp)
    80005f06:	e9ee                	sd	s11,208(sp)
    80005f08:	edf2                	sd	t3,216(sp)
    80005f0a:	f1f6                	sd	t4,224(sp)
    80005f0c:	f5fa                	sd	t5,232(sp)
    80005f0e:	f9fe                	sd	t6,240(sp)
    80005f10:	c8bfc0ef          	jal	ra,80002b9a <kerneltrap>
    80005f14:	6082                	ld	ra,0(sp)
    80005f16:	6122                	ld	sp,8(sp)
    80005f18:	61c2                	ld	gp,16(sp)
    80005f1a:	7282                	ld	t0,32(sp)
    80005f1c:	7322                	ld	t1,40(sp)
    80005f1e:	73c2                	ld	t2,48(sp)
    80005f20:	7462                	ld	s0,56(sp)
    80005f22:	6486                	ld	s1,64(sp)
    80005f24:	6526                	ld	a0,72(sp)
    80005f26:	65c6                	ld	a1,80(sp)
    80005f28:	6666                	ld	a2,88(sp)
    80005f2a:	7686                	ld	a3,96(sp)
    80005f2c:	7726                	ld	a4,104(sp)
    80005f2e:	77c6                	ld	a5,112(sp)
    80005f30:	7866                	ld	a6,120(sp)
    80005f32:	688a                	ld	a7,128(sp)
    80005f34:	692a                	ld	s2,136(sp)
    80005f36:	69ca                	ld	s3,144(sp)
    80005f38:	6a6a                	ld	s4,152(sp)
    80005f3a:	7a8a                	ld	s5,160(sp)
    80005f3c:	7b2a                	ld	s6,168(sp)
    80005f3e:	7bca                	ld	s7,176(sp)
    80005f40:	7c6a                	ld	s8,184(sp)
    80005f42:	6c8e                	ld	s9,192(sp)
    80005f44:	6d2e                	ld	s10,200(sp)
    80005f46:	6dce                	ld	s11,208(sp)
    80005f48:	6e6e                	ld	t3,216(sp)
    80005f4a:	7e8e                	ld	t4,224(sp)
    80005f4c:	7f2e                	ld	t5,232(sp)
    80005f4e:	7fce                	ld	t6,240(sp)
    80005f50:	6111                	addi	sp,sp,256
    80005f52:	10200073          	sret
    80005f56:	00000013          	nop
    80005f5a:	00000013          	nop
    80005f5e:	0001                	nop

0000000080005f60 <timervec>:
    80005f60:	34051573          	csrrw	a0,mscratch,a0
    80005f64:	e10c                	sd	a1,0(a0)
    80005f66:	e510                	sd	a2,8(a0)
    80005f68:	e914                	sd	a3,16(a0)
    80005f6a:	6d0c                	ld	a1,24(a0)
    80005f6c:	7110                	ld	a2,32(a0)
    80005f6e:	6194                	ld	a3,0(a1)
    80005f70:	96b2                	add	a3,a3,a2
    80005f72:	e194                	sd	a3,0(a1)
    80005f74:	4589                	li	a1,2
    80005f76:	14459073          	csrw	sip,a1
    80005f7a:	6914                	ld	a3,16(a0)
    80005f7c:	6510                	ld	a2,8(a0)
    80005f7e:	610c                	ld	a1,0(a0)
    80005f80:	34051573          	csrrw	a0,mscratch,a0
    80005f84:	30200073          	mret
	...

0000000080005f8a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f8a:	1141                	addi	sp,sp,-16
    80005f8c:	e422                	sd	s0,8(sp)
    80005f8e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f90:	0c0007b7          	lui	a5,0xc000
    80005f94:	4705                	li	a4,1
    80005f96:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f98:	c3d8                	sw	a4,4(a5)
}
    80005f9a:	6422                	ld	s0,8(sp)
    80005f9c:	0141                	addi	sp,sp,16
    80005f9e:	8082                	ret

0000000080005fa0 <plicinithart>:

void
plicinithart(void)
{
    80005fa0:	1141                	addi	sp,sp,-16
    80005fa2:	e406                	sd	ra,8(sp)
    80005fa4:	e022                	sd	s0,0(sp)
    80005fa6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa8:	ffffc097          	auipc	ra,0xffffc
    80005fac:	9be080e7          	jalr	-1602(ra) # 80001966 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fb0:	0085171b          	slliw	a4,a0,0x8
    80005fb4:	0c0027b7          	lui	a5,0xc002
    80005fb8:	97ba                	add	a5,a5,a4
    80005fba:	40200713          	li	a4,1026
    80005fbe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fc2:	00d5151b          	slliw	a0,a0,0xd
    80005fc6:	0c2017b7          	lui	a5,0xc201
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	00052023          	sw	zero,0(a0)
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret

0000000080005fd8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fd8:	1141                	addi	sp,sp,-16
    80005fda:	e406                	sd	ra,8(sp)
    80005fdc:	e022                	sd	s0,0(sp)
    80005fde:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe0:	ffffc097          	auipc	ra,0xffffc
    80005fe4:	986080e7          	jalr	-1658(ra) # 80001966 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fe8:	00d5179b          	slliw	a5,a0,0xd
    80005fec:	0c201537          	lui	a0,0xc201
    80005ff0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ff2:	4148                	lw	a0,4(a0)
    80005ff4:	60a2                	ld	ra,8(sp)
    80005ff6:	6402                	ld	s0,0(sp)
    80005ff8:	0141                	addi	sp,sp,16
    80005ffa:	8082                	ret

0000000080005ffc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ffc:	1101                	addi	sp,sp,-32
    80005ffe:	ec06                	sd	ra,24(sp)
    80006000:	e822                	sd	s0,16(sp)
    80006002:	e426                	sd	s1,8(sp)
    80006004:	1000                	addi	s0,sp,32
    80006006:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006008:	ffffc097          	auipc	ra,0xffffc
    8000600c:	95e080e7          	jalr	-1698(ra) # 80001966 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006010:	00d5151b          	slliw	a0,a0,0xd
    80006014:	0c2017b7          	lui	a5,0xc201
    80006018:	97aa                	add	a5,a5,a0
    8000601a:	c3c4                	sw	s1,4(a5)
}
    8000601c:	60e2                	ld	ra,24(sp)
    8000601e:	6442                	ld	s0,16(sp)
    80006020:	64a2                	ld	s1,8(sp)
    80006022:	6105                	addi	sp,sp,32
    80006024:	8082                	ret

0000000080006026 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006026:	1141                	addi	sp,sp,-16
    80006028:	e406                	sd	ra,8(sp)
    8000602a:	e022                	sd	s0,0(sp)
    8000602c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000602e:	479d                	li	a5,7
    80006030:	06a7c963          	blt	a5,a0,800060a2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006034:	0001d797          	auipc	a5,0x1d
    80006038:	fcc78793          	addi	a5,a5,-52 # 80023000 <disk>
    8000603c:	00a78733          	add	a4,a5,a0
    80006040:	6789                	lui	a5,0x2
    80006042:	97ba                	add	a5,a5,a4
    80006044:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006048:	e7ad                	bnez	a5,800060b2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000604a:	00451793          	slli	a5,a0,0x4
    8000604e:	0001f717          	auipc	a4,0x1f
    80006052:	fb270713          	addi	a4,a4,-78 # 80025000 <disk+0x2000>
    80006056:	6314                	ld	a3,0(a4)
    80006058:	96be                	add	a3,a3,a5
    8000605a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000605e:	6314                	ld	a3,0(a4)
    80006060:	96be                	add	a3,a3,a5
    80006062:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006066:	6314                	ld	a3,0(a4)
    80006068:	96be                	add	a3,a3,a5
    8000606a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000606e:	6318                	ld	a4,0(a4)
    80006070:	97ba                	add	a5,a5,a4
    80006072:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006076:	0001d797          	auipc	a5,0x1d
    8000607a:	f8a78793          	addi	a5,a5,-118 # 80023000 <disk>
    8000607e:	97aa                	add	a5,a5,a0
    80006080:	6509                	lui	a0,0x2
    80006082:	953e                	add	a0,a0,a5
    80006084:	4785                	li	a5,1
    80006086:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000608a:	0001f517          	auipc	a0,0x1f
    8000608e:	f8e50513          	addi	a0,a0,-114 # 80025018 <disk+0x2018>
    80006092:	ffffc097          	auipc	ra,0xffffc
    80006096:	1bc080e7          	jalr	444(ra) # 8000224e <wakeup>
}
    8000609a:	60a2                	ld	ra,8(sp)
    8000609c:	6402                	ld	s0,0(sp)
    8000609e:	0141                	addi	sp,sp,16
    800060a0:	8082                	ret
    panic("free_desc 1");
    800060a2:	00003517          	auipc	a0,0x3
    800060a6:	9c650513          	addi	a0,a0,-1594 # 80008a68 <syscalls_str+0x330>
    800060aa:	ffffa097          	auipc	ra,0xffffa
    800060ae:	480080e7          	jalr	1152(ra) # 8000052a <panic>
    panic("free_desc 2");
    800060b2:	00003517          	auipc	a0,0x3
    800060b6:	9c650513          	addi	a0,a0,-1594 # 80008a78 <syscalls_str+0x340>
    800060ba:	ffffa097          	auipc	ra,0xffffa
    800060be:	470080e7          	jalr	1136(ra) # 8000052a <panic>

00000000800060c2 <virtio_disk_init>:
{
    800060c2:	1101                	addi	sp,sp,-32
    800060c4:	ec06                	sd	ra,24(sp)
    800060c6:	e822                	sd	s0,16(sp)
    800060c8:	e426                	sd	s1,8(sp)
    800060ca:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060cc:	00003597          	auipc	a1,0x3
    800060d0:	9bc58593          	addi	a1,a1,-1604 # 80008a88 <syscalls_str+0x350>
    800060d4:	0001f517          	auipc	a0,0x1f
    800060d8:	05450513          	addi	a0,a0,84 # 80025128 <disk+0x2128>
    800060dc:	ffffb097          	auipc	ra,0xffffb
    800060e0:	a56080e7          	jalr	-1450(ra) # 80000b32 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060e4:	100017b7          	lui	a5,0x10001
    800060e8:	4398                	lw	a4,0(a5)
    800060ea:	2701                	sext.w	a4,a4
    800060ec:	747277b7          	lui	a5,0x74727
    800060f0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060f4:	0ef71163          	bne	a4,a5,800061d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800060f8:	100017b7          	lui	a5,0x10001
    800060fc:	43dc                	lw	a5,4(a5)
    800060fe:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006100:	4705                	li	a4,1
    80006102:	0ce79a63          	bne	a5,a4,800061d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006106:	100017b7          	lui	a5,0x10001
    8000610a:	479c                	lw	a5,8(a5)
    8000610c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000610e:	4709                	li	a4,2
    80006110:	0ce79363          	bne	a5,a4,800061d6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006114:	100017b7          	lui	a5,0x10001
    80006118:	47d8                	lw	a4,12(a5)
    8000611a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000611c:	554d47b7          	lui	a5,0x554d4
    80006120:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006124:	0af71963          	bne	a4,a5,800061d6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006128:	100017b7          	lui	a5,0x10001
    8000612c:	4705                	li	a4,1
    8000612e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006130:	470d                	li	a4,3
    80006132:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006134:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006136:	c7ffe737          	lui	a4,0xc7ffe
    8000613a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    8000613e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006140:	2701                	sext.w	a4,a4
    80006142:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006144:	472d                	li	a4,11
    80006146:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006148:	473d                	li	a4,15
    8000614a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000614c:	6705                	lui	a4,0x1
    8000614e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006150:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006154:	5bdc                	lw	a5,52(a5)
    80006156:	2781                	sext.w	a5,a5
  if(max == 0)
    80006158:	c7d9                	beqz	a5,800061e6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000615a:	471d                	li	a4,7
    8000615c:	08f77d63          	bgeu	a4,a5,800061f6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006160:	100014b7          	lui	s1,0x10001
    80006164:	47a1                	li	a5,8
    80006166:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006168:	6609                	lui	a2,0x2
    8000616a:	4581                	li	a1,0
    8000616c:	0001d517          	auipc	a0,0x1d
    80006170:	e9450513          	addi	a0,a0,-364 # 80023000 <disk>
    80006174:	ffffb097          	auipc	ra,0xffffb
    80006178:	b4a080e7          	jalr	-1206(ra) # 80000cbe <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000617c:	0001d717          	auipc	a4,0x1d
    80006180:	e8470713          	addi	a4,a4,-380 # 80023000 <disk>
    80006184:	00c75793          	srli	a5,a4,0xc
    80006188:	2781                	sext.w	a5,a5
    8000618a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000618c:	0001f797          	auipc	a5,0x1f
    80006190:	e7478793          	addi	a5,a5,-396 # 80025000 <disk+0x2000>
    80006194:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006196:	0001d717          	auipc	a4,0x1d
    8000619a:	eea70713          	addi	a4,a4,-278 # 80023080 <disk+0x80>
    8000619e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800061a0:	0001e717          	auipc	a4,0x1e
    800061a4:	e6070713          	addi	a4,a4,-416 # 80024000 <disk+0x1000>
    800061a8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061aa:	4705                	li	a4,1
    800061ac:	00e78c23          	sb	a4,24(a5)
    800061b0:	00e78ca3          	sb	a4,25(a5)
    800061b4:	00e78d23          	sb	a4,26(a5)
    800061b8:	00e78da3          	sb	a4,27(a5)
    800061bc:	00e78e23          	sb	a4,28(a5)
    800061c0:	00e78ea3          	sb	a4,29(a5)
    800061c4:	00e78f23          	sb	a4,30(a5)
    800061c8:	00e78fa3          	sb	a4,31(a5)
}
    800061cc:	60e2                	ld	ra,24(sp)
    800061ce:	6442                	ld	s0,16(sp)
    800061d0:	64a2                	ld	s1,8(sp)
    800061d2:	6105                	addi	sp,sp,32
    800061d4:	8082                	ret
    panic("could not find virtio disk");
    800061d6:	00003517          	auipc	a0,0x3
    800061da:	8c250513          	addi	a0,a0,-1854 # 80008a98 <syscalls_str+0x360>
    800061de:	ffffa097          	auipc	ra,0xffffa
    800061e2:	34c080e7          	jalr	844(ra) # 8000052a <panic>
    panic("virtio disk has no queue 0");
    800061e6:	00003517          	auipc	a0,0x3
    800061ea:	8d250513          	addi	a0,a0,-1838 # 80008ab8 <syscalls_str+0x380>
    800061ee:	ffffa097          	auipc	ra,0xffffa
    800061f2:	33c080e7          	jalr	828(ra) # 8000052a <panic>
    panic("virtio disk max queue too short");
    800061f6:	00003517          	auipc	a0,0x3
    800061fa:	8e250513          	addi	a0,a0,-1822 # 80008ad8 <syscalls_str+0x3a0>
    800061fe:	ffffa097          	auipc	ra,0xffffa
    80006202:	32c080e7          	jalr	812(ra) # 8000052a <panic>

0000000080006206 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006206:	7119                	addi	sp,sp,-128
    80006208:	fc86                	sd	ra,120(sp)
    8000620a:	f8a2                	sd	s0,112(sp)
    8000620c:	f4a6                	sd	s1,104(sp)
    8000620e:	f0ca                	sd	s2,96(sp)
    80006210:	ecce                	sd	s3,88(sp)
    80006212:	e8d2                	sd	s4,80(sp)
    80006214:	e4d6                	sd	s5,72(sp)
    80006216:	e0da                	sd	s6,64(sp)
    80006218:	fc5e                	sd	s7,56(sp)
    8000621a:	f862                	sd	s8,48(sp)
    8000621c:	f466                	sd	s9,40(sp)
    8000621e:	f06a                	sd	s10,32(sp)
    80006220:	ec6e                	sd	s11,24(sp)
    80006222:	0100                	addi	s0,sp,128
    80006224:	8aaa                	mv	s5,a0
    80006226:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006228:	00c52c83          	lw	s9,12(a0)
    8000622c:	001c9c9b          	slliw	s9,s9,0x1
    80006230:	1c82                	slli	s9,s9,0x20
    80006232:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006236:	0001f517          	auipc	a0,0x1f
    8000623a:	ef250513          	addi	a0,a0,-270 # 80025128 <disk+0x2128>
    8000623e:	ffffb097          	auipc	ra,0xffffb
    80006242:	984080e7          	jalr	-1660(ra) # 80000bc2 <acquire>
  for(int i = 0; i < 3; i++){
    80006246:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006248:	44a1                	li	s1,8
      disk.free[i] = 0;
    8000624a:	0001dc17          	auipc	s8,0x1d
    8000624e:	db6c0c13          	addi	s8,s8,-586 # 80023000 <disk>
    80006252:	6b89                	lui	s7,0x2
  for(int i = 0; i < 3; i++){
    80006254:	4b0d                	li	s6,3
    80006256:	a0ad                	j	800062c0 <virtio_disk_rw+0xba>
      disk.free[i] = 0;
    80006258:	00fc0733          	add	a4,s8,a5
    8000625c:	975e                	add	a4,a4,s7
    8000625e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006262:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006264:	0207c563          	bltz	a5,8000628e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006268:	2905                	addiw	s2,s2,1
    8000626a:	0611                	addi	a2,a2,4
    8000626c:	19690d63          	beq	s2,s6,80006406 <virtio_disk_rw+0x200>
    idx[i] = alloc_desc();
    80006270:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006272:	0001f717          	auipc	a4,0x1f
    80006276:	da670713          	addi	a4,a4,-602 # 80025018 <disk+0x2018>
    8000627a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000627c:	00074683          	lbu	a3,0(a4)
    80006280:	fee1                	bnez	a3,80006258 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006282:	2785                	addiw	a5,a5,1
    80006284:	0705                	addi	a4,a4,1
    80006286:	fe979be3          	bne	a5,s1,8000627c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000628a:	57fd                	li	a5,-1
    8000628c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000628e:	01205d63          	blez	s2,800062a8 <virtio_disk_rw+0xa2>
    80006292:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006294:	000a2503          	lw	a0,0(s4)
    80006298:	00000097          	auipc	ra,0x0
    8000629c:	d8e080e7          	jalr	-626(ra) # 80006026 <free_desc>
      for(int j = 0; j < i; j++)
    800062a0:	2d85                	addiw	s11,s11,1
    800062a2:	0a11                	addi	s4,s4,4
    800062a4:	ffb918e3          	bne	s2,s11,80006294 <virtio_disk_rw+0x8e>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	0001f597          	auipc	a1,0x1f
    800062ac:	e8058593          	addi	a1,a1,-384 # 80025128 <disk+0x2128>
    800062b0:	0001f517          	auipc	a0,0x1f
    800062b4:	d6850513          	addi	a0,a0,-664 # 80025018 <disk+0x2018>
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	e0a080e7          	jalr	-502(ra) # 800020c2 <sleep>
  for(int i = 0; i < 3; i++){
    800062c0:	f8040a13          	addi	s4,s0,-128
{
    800062c4:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800062c6:	894e                	mv	s2,s3
    800062c8:	b765                	j	80006270 <virtio_disk_rw+0x6a>
  disk.desc[idx[0]].next = idx[1];

  disk.desc[idx[1]].addr = (uint64) b->data;
  disk.desc[idx[1]].len = BSIZE;
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062ca:	0001f697          	auipc	a3,0x1f
    800062ce:	d366b683          	ld	a3,-714(a3) # 80025000 <disk+0x2000>
    800062d2:	96ba                	add	a3,a3,a4
    800062d4:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062d8:	0001d817          	auipc	a6,0x1d
    800062dc:	d2880813          	addi	a6,a6,-728 # 80023000 <disk>
    800062e0:	0001f697          	auipc	a3,0x1f
    800062e4:	d2068693          	addi	a3,a3,-736 # 80025000 <disk+0x2000>
    800062e8:	6290                	ld	a2,0(a3)
    800062ea:	963a                	add	a2,a2,a4
    800062ec:	00c65583          	lhu	a1,12(a2) # 200c <_entry-0x7fffdff4>
    800062f0:	0015e593          	ori	a1,a1,1
    800062f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800062f8:	f8842603          	lw	a2,-120(s0)
    800062fc:	628c                	ld	a1,0(a3)
    800062fe:	972e                	add	a4,a4,a1
    80006300:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006304:	20050593          	addi	a1,a0,512
    80006308:	0592                	slli	a1,a1,0x4
    8000630a:	95c2                	add	a1,a1,a6
    8000630c:	577d                	li	a4,-1
    8000630e:	02e58823          	sb	a4,48(a1)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006312:	00461713          	slli	a4,a2,0x4
    80006316:	6290                	ld	a2,0(a3)
    80006318:	963a                	add	a2,a2,a4
    8000631a:	03078793          	addi	a5,a5,48
    8000631e:	97c2                	add	a5,a5,a6
    80006320:	e21c                	sd	a5,0(a2)
  disk.desc[idx[2]].len = 1;
    80006322:	629c                	ld	a5,0(a3)
    80006324:	97ba                	add	a5,a5,a4
    80006326:	4605                	li	a2,1
    80006328:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000632a:	629c                	ld	a5,0(a3)
    8000632c:	97ba                	add	a5,a5,a4
    8000632e:	4809                	li	a6,2
    80006330:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006334:	629c                	ld	a5,0(a3)
    80006336:	973e                	add	a4,a4,a5
    80006338:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000633c:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    80006340:	0355b423          	sd	s5,40(a1)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006344:	6698                	ld	a4,8(a3)
    80006346:	00275783          	lhu	a5,2(a4)
    8000634a:	8b9d                	andi	a5,a5,7
    8000634c:	0786                	slli	a5,a5,0x1
    8000634e:	97ba                	add	a5,a5,a4
    80006350:	00a79223          	sh	a0,4(a5)

  __sync_synchronize();
    80006354:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006358:	6698                	ld	a4,8(a3)
    8000635a:	00275783          	lhu	a5,2(a4)
    8000635e:	2785                	addiw	a5,a5,1
    80006360:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006364:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006370:	004aa783          	lw	a5,4(s5)
    80006374:	02c79163          	bne	a5,a2,80006396 <virtio_disk_rw+0x190>
    sleep(b, &disk.vdisk_lock);
    80006378:	0001f917          	auipc	s2,0x1f
    8000637c:	db090913          	addi	s2,s2,-592 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    80006380:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006382:	85ca                	mv	a1,s2
    80006384:	8556                	mv	a0,s5
    80006386:	ffffc097          	auipc	ra,0xffffc
    8000638a:	d3c080e7          	jalr	-708(ra) # 800020c2 <sleep>
  while(b->disk == 1) {
    8000638e:	004aa783          	lw	a5,4(s5)
    80006392:	fe9788e3          	beq	a5,s1,80006382 <virtio_disk_rw+0x17c>
  }

  disk.info[idx[0]].b = 0;
    80006396:	f8042903          	lw	s2,-128(s0)
    8000639a:	20090793          	addi	a5,s2,512
    8000639e:	00479713          	slli	a4,a5,0x4
    800063a2:	0001d797          	auipc	a5,0x1d
    800063a6:	c5e78793          	addi	a5,a5,-930 # 80023000 <disk>
    800063aa:	97ba                	add	a5,a5,a4
    800063ac:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800063b0:	0001f997          	auipc	s3,0x1f
    800063b4:	c5098993          	addi	s3,s3,-944 # 80025000 <disk+0x2000>
    800063b8:	00491713          	slli	a4,s2,0x4
    800063bc:	0009b783          	ld	a5,0(s3)
    800063c0:	97ba                	add	a5,a5,a4
    800063c2:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063c6:	854a                	mv	a0,s2
    800063c8:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063cc:	00000097          	auipc	ra,0x0
    800063d0:	c5a080e7          	jalr	-934(ra) # 80006026 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063d4:	8885                	andi	s1,s1,1
    800063d6:	f0ed                	bnez	s1,800063b8 <virtio_disk_rw+0x1b2>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063d8:	0001f517          	auipc	a0,0x1f
    800063dc:	d5050513          	addi	a0,a0,-688 # 80025128 <disk+0x2128>
    800063e0:	ffffb097          	auipc	ra,0xffffb
    800063e4:	896080e7          	jalr	-1898(ra) # 80000c76 <release>
}
    800063e8:	70e6                	ld	ra,120(sp)
    800063ea:	7446                	ld	s0,112(sp)
    800063ec:	74a6                	ld	s1,104(sp)
    800063ee:	7906                	ld	s2,96(sp)
    800063f0:	69e6                	ld	s3,88(sp)
    800063f2:	6a46                	ld	s4,80(sp)
    800063f4:	6aa6                	ld	s5,72(sp)
    800063f6:	6b06                	ld	s6,64(sp)
    800063f8:	7be2                	ld	s7,56(sp)
    800063fa:	7c42                	ld	s8,48(sp)
    800063fc:	7ca2                	ld	s9,40(sp)
    800063fe:	7d02                	ld	s10,32(sp)
    80006400:	6de2                	ld	s11,24(sp)
    80006402:	6109                	addi	sp,sp,128
    80006404:	8082                	ret
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006406:	f8042503          	lw	a0,-128(s0)
    8000640a:	20050793          	addi	a5,a0,512
    8000640e:	0792                	slli	a5,a5,0x4
  if(write)
    80006410:	0001d817          	auipc	a6,0x1d
    80006414:	bf080813          	addi	a6,a6,-1040 # 80023000 <disk>
    80006418:	00f80733          	add	a4,a6,a5
    8000641c:	01a036b3          	snez	a3,s10
    80006420:	0ad72423          	sw	a3,168(a4)
  buf0->reserved = 0;
    80006424:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006428:	0b973823          	sd	s9,176(a4)
  disk.desc[idx[0]].addr = (uint64) buf0;
    8000642c:	7679                	lui	a2,0xffffe
    8000642e:	963e                	add	a2,a2,a5
    80006430:	0001f697          	auipc	a3,0x1f
    80006434:	bd068693          	addi	a3,a3,-1072 # 80025000 <disk+0x2000>
    80006438:	6298                	ld	a4,0(a3)
    8000643a:	9732                	add	a4,a4,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000643c:	0a878593          	addi	a1,a5,168
    80006440:	95c2                	add	a1,a1,a6
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006442:	e30c                	sd	a1,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006444:	6298                	ld	a4,0(a3)
    80006446:	9732                	add	a4,a4,a2
    80006448:	45c1                	li	a1,16
    8000644a:	c70c                	sw	a1,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000644c:	6298                	ld	a4,0(a3)
    8000644e:	9732                	add	a4,a4,a2
    80006450:	4585                	li	a1,1
    80006452:	00b71623          	sh	a1,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006456:	f8442703          	lw	a4,-124(s0)
    8000645a:	628c                	ld	a1,0(a3)
    8000645c:	962e                	add	a2,a2,a1
    8000645e:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>
  disk.desc[idx[1]].addr = (uint64) b->data;
    80006462:	0712                	slli	a4,a4,0x4
    80006464:	6290                	ld	a2,0(a3)
    80006466:	963a                	add	a2,a2,a4
    80006468:	058a8593          	addi	a1,s5,88
    8000646c:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    8000646e:	6294                	ld	a3,0(a3)
    80006470:	96ba                	add	a3,a3,a4
    80006472:	40000613          	li	a2,1024
    80006476:	c690                	sw	a2,8(a3)
  if(write)
    80006478:	e40d19e3          	bnez	s10,800062ca <virtio_disk_rw+0xc4>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000647c:	0001f697          	auipc	a3,0x1f
    80006480:	b846b683          	ld	a3,-1148(a3) # 80025000 <disk+0x2000>
    80006484:	96ba                	add	a3,a3,a4
    80006486:	4609                	li	a2,2
    80006488:	00c69623          	sh	a2,12(a3)
    8000648c:	b5b1                	j	800062d8 <virtio_disk_rw+0xd2>

000000008000648e <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000648e:	1101                	addi	sp,sp,-32
    80006490:	ec06                	sd	ra,24(sp)
    80006492:	e822                	sd	s0,16(sp)
    80006494:	e426                	sd	s1,8(sp)
    80006496:	e04a                	sd	s2,0(sp)
    80006498:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000649a:	0001f517          	auipc	a0,0x1f
    8000649e:	c8e50513          	addi	a0,a0,-882 # 80025128 <disk+0x2128>
    800064a2:	ffffa097          	auipc	ra,0xffffa
    800064a6:	720080e7          	jalr	1824(ra) # 80000bc2 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064aa:	10001737          	lui	a4,0x10001
    800064ae:	533c                	lw	a5,96(a4)
    800064b0:	8b8d                	andi	a5,a5,3
    800064b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064b8:	0001f797          	auipc	a5,0x1f
    800064bc:	b4878793          	addi	a5,a5,-1208 # 80025000 <disk+0x2000>
    800064c0:	6b94                	ld	a3,16(a5)
    800064c2:	0207d703          	lhu	a4,32(a5)
    800064c6:	0026d783          	lhu	a5,2(a3)
    800064ca:	06f70163          	beq	a4,a5,8000652c <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064ce:	0001d917          	auipc	s2,0x1d
    800064d2:	b3290913          	addi	s2,s2,-1230 # 80023000 <disk>
    800064d6:	0001f497          	auipc	s1,0x1f
    800064da:	b2a48493          	addi	s1,s1,-1238 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800064de:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064e2:	6898                	ld	a4,16(s1)
    800064e4:	0204d783          	lhu	a5,32(s1)
    800064e8:	8b9d                	andi	a5,a5,7
    800064ea:	078e                	slli	a5,a5,0x3
    800064ec:	97ba                	add	a5,a5,a4
    800064ee:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064f0:	20078713          	addi	a4,a5,512
    800064f4:	0712                	slli	a4,a4,0x4
    800064f6:	974a                	add	a4,a4,s2
    800064f8:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800064fc:	e731                	bnez	a4,80006548 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064fe:	20078793          	addi	a5,a5,512
    80006502:	0792                	slli	a5,a5,0x4
    80006504:	97ca                	add	a5,a5,s2
    80006506:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006508:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000650c:	ffffc097          	auipc	ra,0xffffc
    80006510:	d42080e7          	jalr	-702(ra) # 8000224e <wakeup>

    disk.used_idx += 1;
    80006514:	0204d783          	lhu	a5,32(s1)
    80006518:	2785                	addiw	a5,a5,1
    8000651a:	17c2                	slli	a5,a5,0x30
    8000651c:	93c1                	srli	a5,a5,0x30
    8000651e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006522:	6898                	ld	a4,16(s1)
    80006524:	00275703          	lhu	a4,2(a4)
    80006528:	faf71be3          	bne	a4,a5,800064de <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000652c:	0001f517          	auipc	a0,0x1f
    80006530:	bfc50513          	addi	a0,a0,-1028 # 80025128 <disk+0x2128>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	742080e7          	jalr	1858(ra) # 80000c76 <release>
}
    8000653c:	60e2                	ld	ra,24(sp)
    8000653e:	6442                	ld	s0,16(sp)
    80006540:	64a2                	ld	s1,8(sp)
    80006542:	6902                	ld	s2,0(sp)
    80006544:	6105                	addi	sp,sp,32
    80006546:	8082                	ret
      panic("virtio_disk_intr status");
    80006548:	00002517          	auipc	a0,0x2
    8000654c:	5b050513          	addi	a0,a0,1456 # 80008af8 <syscalls_str+0x3c0>
    80006550:	ffffa097          	auipc	ra,0xffffa
    80006554:	fda080e7          	jalr	-38(ra) # 8000052a <panic>
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
