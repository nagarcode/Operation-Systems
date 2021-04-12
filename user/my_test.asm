
user/_my_test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "../kernel/fcntl.h"
#include "../kernel/syscall.h"
//#include "../kernel/defs.h"

int main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    //fprintf(2, "just checking\n");
    int mask;
    mask = (1 << SYS_fork) | (1 << SYS_kill) | (1 << SYS_sbrk) | (1 << SYS_write);
    trace(mask, getpid());
   8:	00000097          	auipc	ra,0x0
   c:	320080e7          	jalr	800(ra) # 328 <getpid>
  10:	85aa                	mv	a1,a0
  12:	6545                	lui	a0,0x11
  14:	04250513          	addi	a0,a0,66 # 11042 <__global_pointer$+0x10051>
  18:	00000097          	auipc	ra,0x0
  1c:	330080e7          	jalr	816(ra) # 348 <trace>
    int pid = fork();
  20:	00000097          	auipc	ra,0x0
  24:	280080e7          	jalr	640(ra) # 2a0 <fork>
    kill(pid);
  28:	00000097          	auipc	ra,0x0
  2c:	2b0080e7          	jalr	688(ra) # 2d8 <kill>
    exit(0);
  30:	4501                	li	a0,0
  32:	00000097          	auipc	ra,0x0
  36:	276080e7          	jalr	630(ra) # 2a8 <exit>

000000000000003a <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  3a:	1141                	addi	sp,sp,-16
  3c:	e422                	sd	s0,8(sp)
  3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  40:	87aa                	mv	a5,a0
  42:	0585                	addi	a1,a1,1
  44:	0785                	addi	a5,a5,1
  46:	fff5c703          	lbu	a4,-1(a1)
  4a:	fee78fa3          	sb	a4,-1(a5)
  4e:	fb75                	bnez	a4,42 <strcpy+0x8>
    ;
  return os;
}
  50:	6422                	ld	s0,8(sp)
  52:	0141                	addi	sp,sp,16
  54:	8082                	ret

0000000000000056 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  56:	1141                	addi	sp,sp,-16
  58:	e422                	sd	s0,8(sp)
  5a:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  5c:	00054783          	lbu	a5,0(a0)
  60:	cb91                	beqz	a5,74 <strcmp+0x1e>
  62:	0005c703          	lbu	a4,0(a1)
  66:	00f71763          	bne	a4,a5,74 <strcmp+0x1e>
    p++, q++;
  6a:	0505                	addi	a0,a0,1
  6c:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  6e:	00054783          	lbu	a5,0(a0)
  72:	fbe5                	bnez	a5,62 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  74:	0005c503          	lbu	a0,0(a1)
}
  78:	40a7853b          	subw	a0,a5,a0
  7c:	6422                	ld	s0,8(sp)
  7e:	0141                	addi	sp,sp,16
  80:	8082                	ret

0000000000000082 <strlen>:

uint
strlen(const char *s)
{
  82:	1141                	addi	sp,sp,-16
  84:	e422                	sd	s0,8(sp)
  86:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  88:	00054783          	lbu	a5,0(a0)
  8c:	cf91                	beqz	a5,a8 <strlen+0x26>
  8e:	0505                	addi	a0,a0,1
  90:	87aa                	mv	a5,a0
  92:	4685                	li	a3,1
  94:	9e89                	subw	a3,a3,a0
  96:	00f6853b          	addw	a0,a3,a5
  9a:	0785                	addi	a5,a5,1
  9c:	fff7c703          	lbu	a4,-1(a5)
  a0:	fb7d                	bnez	a4,96 <strlen+0x14>
    ;
  return n;
}
  a2:	6422                	ld	s0,8(sp)
  a4:	0141                	addi	sp,sp,16
  a6:	8082                	ret
  for(n = 0; s[n]; n++)
  a8:	4501                	li	a0,0
  aa:	bfe5                	j	a2 <strlen+0x20>

00000000000000ac <memset>:

void*
memset(void *dst, int c, uint n)
{
  ac:	1141                	addi	sp,sp,-16
  ae:	e422                	sd	s0,8(sp)
  b0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  b2:	ca19                	beqz	a2,c8 <memset+0x1c>
  b4:	87aa                	mv	a5,a0
  b6:	1602                	slli	a2,a2,0x20
  b8:	9201                	srli	a2,a2,0x20
  ba:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  be:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  c2:	0785                	addi	a5,a5,1
  c4:	fee79de3          	bne	a5,a4,be <memset+0x12>
  }
  return dst;
}
  c8:	6422                	ld	s0,8(sp)
  ca:	0141                	addi	sp,sp,16
  cc:	8082                	ret

00000000000000ce <strchr>:

char*
strchr(const char *s, char c)
{
  ce:	1141                	addi	sp,sp,-16
  d0:	e422                	sd	s0,8(sp)
  d2:	0800                	addi	s0,sp,16
  for(; *s; s++)
  d4:	00054783          	lbu	a5,0(a0)
  d8:	cb99                	beqz	a5,ee <strchr+0x20>
    if(*s == c)
  da:	00f58763          	beq	a1,a5,e8 <strchr+0x1a>
  for(; *s; s++)
  de:	0505                	addi	a0,a0,1
  e0:	00054783          	lbu	a5,0(a0)
  e4:	fbfd                	bnez	a5,da <strchr+0xc>
      return (char*)s;
  return 0;
  e6:	4501                	li	a0,0
}
  e8:	6422                	ld	s0,8(sp)
  ea:	0141                	addi	sp,sp,16
  ec:	8082                	ret
  return 0;
  ee:	4501                	li	a0,0
  f0:	bfe5                	j	e8 <strchr+0x1a>

00000000000000f2 <gets>:

char*
gets(char *buf, int max)
{
  f2:	711d                	addi	sp,sp,-96
  f4:	ec86                	sd	ra,88(sp)
  f6:	e8a2                	sd	s0,80(sp)
  f8:	e4a6                	sd	s1,72(sp)
  fa:	e0ca                	sd	s2,64(sp)
  fc:	fc4e                	sd	s3,56(sp)
  fe:	f852                	sd	s4,48(sp)
 100:	f456                	sd	s5,40(sp)
 102:	f05a                	sd	s6,32(sp)
 104:	ec5e                	sd	s7,24(sp)
 106:	1080                	addi	s0,sp,96
 108:	8baa                	mv	s7,a0
 10a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 10c:	892a                	mv	s2,a0
 10e:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 110:	4aa9                	li	s5,10
 112:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 114:	89a6                	mv	s3,s1
 116:	2485                	addiw	s1,s1,1
 118:	0344d863          	bge	s1,s4,148 <gets+0x56>
    cc = read(0, &c, 1);
 11c:	4605                	li	a2,1
 11e:	faf40593          	addi	a1,s0,-81
 122:	4501                	li	a0,0
 124:	00000097          	auipc	ra,0x0
 128:	19c080e7          	jalr	412(ra) # 2c0 <read>
    if(cc < 1)
 12c:	00a05e63          	blez	a0,148 <gets+0x56>
    buf[i++] = c;
 130:	faf44783          	lbu	a5,-81(s0)
 134:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 138:	01578763          	beq	a5,s5,146 <gets+0x54>
 13c:	0905                	addi	s2,s2,1
 13e:	fd679be3          	bne	a5,s6,114 <gets+0x22>
  for(i=0; i+1 < max; ){
 142:	89a6                	mv	s3,s1
 144:	a011                	j	148 <gets+0x56>
 146:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 148:	99de                	add	s3,s3,s7
 14a:	00098023          	sb	zero,0(s3)
  return buf;
}
 14e:	855e                	mv	a0,s7
 150:	60e6                	ld	ra,88(sp)
 152:	6446                	ld	s0,80(sp)
 154:	64a6                	ld	s1,72(sp)
 156:	6906                	ld	s2,64(sp)
 158:	79e2                	ld	s3,56(sp)
 15a:	7a42                	ld	s4,48(sp)
 15c:	7aa2                	ld	s5,40(sp)
 15e:	7b02                	ld	s6,32(sp)
 160:	6be2                	ld	s7,24(sp)
 162:	6125                	addi	sp,sp,96
 164:	8082                	ret

0000000000000166 <stat>:

int
stat(const char *n, struct stat *st)
{
 166:	1101                	addi	sp,sp,-32
 168:	ec06                	sd	ra,24(sp)
 16a:	e822                	sd	s0,16(sp)
 16c:	e426                	sd	s1,8(sp)
 16e:	e04a                	sd	s2,0(sp)
 170:	1000                	addi	s0,sp,32
 172:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 174:	4581                	li	a1,0
 176:	00000097          	auipc	ra,0x0
 17a:	172080e7          	jalr	370(ra) # 2e8 <open>
  if(fd < 0)
 17e:	02054563          	bltz	a0,1a8 <stat+0x42>
 182:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 184:	85ca                	mv	a1,s2
 186:	00000097          	auipc	ra,0x0
 18a:	17a080e7          	jalr	378(ra) # 300 <fstat>
 18e:	892a                	mv	s2,a0
  close(fd);
 190:	8526                	mv	a0,s1
 192:	00000097          	auipc	ra,0x0
 196:	13e080e7          	jalr	318(ra) # 2d0 <close>
  return r;
}
 19a:	854a                	mv	a0,s2
 19c:	60e2                	ld	ra,24(sp)
 19e:	6442                	ld	s0,16(sp)
 1a0:	64a2                	ld	s1,8(sp)
 1a2:	6902                	ld	s2,0(sp)
 1a4:	6105                	addi	sp,sp,32
 1a6:	8082                	ret
    return -1;
 1a8:	597d                	li	s2,-1
 1aa:	bfc5                	j	19a <stat+0x34>

00000000000001ac <atoi>:

int
atoi(const char *s)
{
 1ac:	1141                	addi	sp,sp,-16
 1ae:	e422                	sd	s0,8(sp)
 1b0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1b2:	00054603          	lbu	a2,0(a0)
 1b6:	fd06079b          	addiw	a5,a2,-48
 1ba:	0ff7f793          	andi	a5,a5,255
 1be:	4725                	li	a4,9
 1c0:	02f76963          	bltu	a4,a5,1f2 <atoi+0x46>
 1c4:	86aa                	mv	a3,a0
  n = 0;
 1c6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1c8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1ca:	0685                	addi	a3,a3,1
 1cc:	0025179b          	slliw	a5,a0,0x2
 1d0:	9fa9                	addw	a5,a5,a0
 1d2:	0017979b          	slliw	a5,a5,0x1
 1d6:	9fb1                	addw	a5,a5,a2
 1d8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1dc:	0006c603          	lbu	a2,0(a3)
 1e0:	fd06071b          	addiw	a4,a2,-48
 1e4:	0ff77713          	andi	a4,a4,255
 1e8:	fee5f1e3          	bgeu	a1,a4,1ca <atoi+0x1e>
  return n;
}
 1ec:	6422                	ld	s0,8(sp)
 1ee:	0141                	addi	sp,sp,16
 1f0:	8082                	ret
  n = 0;
 1f2:	4501                	li	a0,0
 1f4:	bfe5                	j	1ec <atoi+0x40>

00000000000001f6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1f6:	1141                	addi	sp,sp,-16
 1f8:	e422                	sd	s0,8(sp)
 1fa:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1fc:	02b57463          	bgeu	a0,a1,224 <memmove+0x2e>
    while(n-- > 0)
 200:	00c05f63          	blez	a2,21e <memmove+0x28>
 204:	1602                	slli	a2,a2,0x20
 206:	9201                	srli	a2,a2,0x20
 208:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 20c:	872a                	mv	a4,a0
      *dst++ = *src++;
 20e:	0585                	addi	a1,a1,1
 210:	0705                	addi	a4,a4,1
 212:	fff5c683          	lbu	a3,-1(a1)
 216:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 21a:	fee79ae3          	bne	a5,a4,20e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 21e:	6422                	ld	s0,8(sp)
 220:	0141                	addi	sp,sp,16
 222:	8082                	ret
    dst += n;
 224:	00c50733          	add	a4,a0,a2
    src += n;
 228:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 22a:	fec05ae3          	blez	a2,21e <memmove+0x28>
 22e:	fff6079b          	addiw	a5,a2,-1
 232:	1782                	slli	a5,a5,0x20
 234:	9381                	srli	a5,a5,0x20
 236:	fff7c793          	not	a5,a5
 23a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 23c:	15fd                	addi	a1,a1,-1
 23e:	177d                	addi	a4,a4,-1
 240:	0005c683          	lbu	a3,0(a1)
 244:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 248:	fee79ae3          	bne	a5,a4,23c <memmove+0x46>
 24c:	bfc9                	j	21e <memmove+0x28>

000000000000024e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 24e:	1141                	addi	sp,sp,-16
 250:	e422                	sd	s0,8(sp)
 252:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 254:	ca05                	beqz	a2,284 <memcmp+0x36>
 256:	fff6069b          	addiw	a3,a2,-1
 25a:	1682                	slli	a3,a3,0x20
 25c:	9281                	srli	a3,a3,0x20
 25e:	0685                	addi	a3,a3,1
 260:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 262:	00054783          	lbu	a5,0(a0)
 266:	0005c703          	lbu	a4,0(a1)
 26a:	00e79863          	bne	a5,a4,27a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 26e:	0505                	addi	a0,a0,1
    p2++;
 270:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 272:	fed518e3          	bne	a0,a3,262 <memcmp+0x14>
  }
  return 0;
 276:	4501                	li	a0,0
 278:	a019                	j	27e <memcmp+0x30>
      return *p1 - *p2;
 27a:	40e7853b          	subw	a0,a5,a4
}
 27e:	6422                	ld	s0,8(sp)
 280:	0141                	addi	sp,sp,16
 282:	8082                	ret
  return 0;
 284:	4501                	li	a0,0
 286:	bfe5                	j	27e <memcmp+0x30>

0000000000000288 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 288:	1141                	addi	sp,sp,-16
 28a:	e406                	sd	ra,8(sp)
 28c:	e022                	sd	s0,0(sp)
 28e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 290:	00000097          	auipc	ra,0x0
 294:	f66080e7          	jalr	-154(ra) # 1f6 <memmove>
}
 298:	60a2                	ld	ra,8(sp)
 29a:	6402                	ld	s0,0(sp)
 29c:	0141                	addi	sp,sp,16
 29e:	8082                	ret

00000000000002a0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2a0:	4885                	li	a7,1
 ecall
 2a2:	00000073          	ecall
 ret
 2a6:	8082                	ret

00000000000002a8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2a8:	4889                	li	a7,2
 ecall
 2aa:	00000073          	ecall
 ret
 2ae:	8082                	ret

00000000000002b0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2b0:	488d                	li	a7,3
 ecall
 2b2:	00000073          	ecall
 ret
 2b6:	8082                	ret

00000000000002b8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2b8:	4891                	li	a7,4
 ecall
 2ba:	00000073          	ecall
 ret
 2be:	8082                	ret

00000000000002c0 <read>:
.global read
read:
 li a7, SYS_read
 2c0:	4895                	li	a7,5
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <write>:
.global write
write:
 li a7, SYS_write
 2c8:	48c1                	li	a7,16
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <close>:
.global close
close:
 li a7, SYS_close
 2d0:	48d5                	li	a7,21
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2d8:	4899                	li	a7,6
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2e0:	489d                	li	a7,7
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <open>:
.global open
open:
 li a7, SYS_open
 2e8:	48bd                	li	a7,15
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2f0:	48c5                	li	a7,17
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2f8:	48c9                	li	a7,18
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 300:	48a1                	li	a7,8
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <link>:
.global link
link:
 li a7, SYS_link
 308:	48cd                	li	a7,19
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 310:	48d1                	li	a7,20
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 318:	48a5                	li	a7,9
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <dup>:
.global dup
dup:
 li a7, SYS_dup
 320:	48a9                	li	a7,10
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 328:	48ad                	li	a7,11
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 330:	48b1                	li	a7,12
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 338:	48b5                	li	a7,13
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 340:	48b9                	li	a7,14
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <trace>:
.global trace
trace:
 li a7, SYS_trace
 348:	48d9                	li	a7,22
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <wait_stat>:
.global wait_stat
wait_stat:
 li a7, SYS_wait_stat
 350:	48dd                	li	a7,23
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 358:	1101                	addi	sp,sp,-32
 35a:	ec06                	sd	ra,24(sp)
 35c:	e822                	sd	s0,16(sp)
 35e:	1000                	addi	s0,sp,32
 360:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 364:	4605                	li	a2,1
 366:	fef40593          	addi	a1,s0,-17
 36a:	00000097          	auipc	ra,0x0
 36e:	f5e080e7          	jalr	-162(ra) # 2c8 <write>
}
 372:	60e2                	ld	ra,24(sp)
 374:	6442                	ld	s0,16(sp)
 376:	6105                	addi	sp,sp,32
 378:	8082                	ret

000000000000037a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 37a:	7139                	addi	sp,sp,-64
 37c:	fc06                	sd	ra,56(sp)
 37e:	f822                	sd	s0,48(sp)
 380:	f426                	sd	s1,40(sp)
 382:	f04a                	sd	s2,32(sp)
 384:	ec4e                	sd	s3,24(sp)
 386:	0080                	addi	s0,sp,64
 388:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 38a:	c299                	beqz	a3,390 <printint+0x16>
 38c:	0805c863          	bltz	a1,41c <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 390:	2581                	sext.w	a1,a1
  neg = 0;
 392:	4881                	li	a7,0
 394:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 398:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 39a:	2601                	sext.w	a2,a2
 39c:	00000517          	auipc	a0,0x0
 3a0:	44450513          	addi	a0,a0,1092 # 7e0 <digits>
 3a4:	883a                	mv	a6,a4
 3a6:	2705                	addiw	a4,a4,1
 3a8:	02c5f7bb          	remuw	a5,a1,a2
 3ac:	1782                	slli	a5,a5,0x20
 3ae:	9381                	srli	a5,a5,0x20
 3b0:	97aa                	add	a5,a5,a0
 3b2:	0007c783          	lbu	a5,0(a5)
 3b6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ba:	0005879b          	sext.w	a5,a1
 3be:	02c5d5bb          	divuw	a1,a1,a2
 3c2:	0685                	addi	a3,a3,1
 3c4:	fec7f0e3          	bgeu	a5,a2,3a4 <printint+0x2a>
  if(neg)
 3c8:	00088b63          	beqz	a7,3de <printint+0x64>
    buf[i++] = '-';
 3cc:	fd040793          	addi	a5,s0,-48
 3d0:	973e                	add	a4,a4,a5
 3d2:	02d00793          	li	a5,45
 3d6:	fef70823          	sb	a5,-16(a4)
 3da:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3de:	02e05863          	blez	a4,40e <printint+0x94>
 3e2:	fc040793          	addi	a5,s0,-64
 3e6:	00e78933          	add	s2,a5,a4
 3ea:	fff78993          	addi	s3,a5,-1
 3ee:	99ba                	add	s3,s3,a4
 3f0:	377d                	addiw	a4,a4,-1
 3f2:	1702                	slli	a4,a4,0x20
 3f4:	9301                	srli	a4,a4,0x20
 3f6:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3fa:	fff94583          	lbu	a1,-1(s2)
 3fe:	8526                	mv	a0,s1
 400:	00000097          	auipc	ra,0x0
 404:	f58080e7          	jalr	-168(ra) # 358 <putc>
  while(--i >= 0)
 408:	197d                	addi	s2,s2,-1
 40a:	ff3918e3          	bne	s2,s3,3fa <printint+0x80>
}
 40e:	70e2                	ld	ra,56(sp)
 410:	7442                	ld	s0,48(sp)
 412:	74a2                	ld	s1,40(sp)
 414:	7902                	ld	s2,32(sp)
 416:	69e2                	ld	s3,24(sp)
 418:	6121                	addi	sp,sp,64
 41a:	8082                	ret
    x = -xx;
 41c:	40b005bb          	negw	a1,a1
    neg = 1;
 420:	4885                	li	a7,1
    x = -xx;
 422:	bf8d                	j	394 <printint+0x1a>

0000000000000424 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 424:	7119                	addi	sp,sp,-128
 426:	fc86                	sd	ra,120(sp)
 428:	f8a2                	sd	s0,112(sp)
 42a:	f4a6                	sd	s1,104(sp)
 42c:	f0ca                	sd	s2,96(sp)
 42e:	ecce                	sd	s3,88(sp)
 430:	e8d2                	sd	s4,80(sp)
 432:	e4d6                	sd	s5,72(sp)
 434:	e0da                	sd	s6,64(sp)
 436:	fc5e                	sd	s7,56(sp)
 438:	f862                	sd	s8,48(sp)
 43a:	f466                	sd	s9,40(sp)
 43c:	f06a                	sd	s10,32(sp)
 43e:	ec6e                	sd	s11,24(sp)
 440:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 442:	0005c903          	lbu	s2,0(a1)
 446:	18090f63          	beqz	s2,5e4 <vprintf+0x1c0>
 44a:	8aaa                	mv	s5,a0
 44c:	8b32                	mv	s6,a2
 44e:	00158493          	addi	s1,a1,1
  state = 0;
 452:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 454:	02500a13          	li	s4,37
      if(c == 'd'){
 458:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 45c:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 460:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 464:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 468:	00000b97          	auipc	s7,0x0
 46c:	378b8b93          	addi	s7,s7,888 # 7e0 <digits>
 470:	a839                	j	48e <vprintf+0x6a>
        putc(fd, c);
 472:	85ca                	mv	a1,s2
 474:	8556                	mv	a0,s5
 476:	00000097          	auipc	ra,0x0
 47a:	ee2080e7          	jalr	-286(ra) # 358 <putc>
 47e:	a019                	j	484 <vprintf+0x60>
    } else if(state == '%'){
 480:	01498f63          	beq	s3,s4,49e <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 484:	0485                	addi	s1,s1,1
 486:	fff4c903          	lbu	s2,-1(s1)
 48a:	14090d63          	beqz	s2,5e4 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 48e:	0009079b          	sext.w	a5,s2
    if(state == 0){
 492:	fe0997e3          	bnez	s3,480 <vprintf+0x5c>
      if(c == '%'){
 496:	fd479ee3          	bne	a5,s4,472 <vprintf+0x4e>
        state = '%';
 49a:	89be                	mv	s3,a5
 49c:	b7e5                	j	484 <vprintf+0x60>
      if(c == 'd'){
 49e:	05878063          	beq	a5,s8,4de <vprintf+0xba>
      } else if(c == 'l') {
 4a2:	05978c63          	beq	a5,s9,4fa <vprintf+0xd6>
      } else if(c == 'x') {
 4a6:	07a78863          	beq	a5,s10,516 <vprintf+0xf2>
      } else if(c == 'p') {
 4aa:	09b78463          	beq	a5,s11,532 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4ae:	07300713          	li	a4,115
 4b2:	0ce78663          	beq	a5,a4,57e <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4b6:	06300713          	li	a4,99
 4ba:	0ee78e63          	beq	a5,a4,5b6 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4be:	11478863          	beq	a5,s4,5ce <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4c2:	85d2                	mv	a1,s4
 4c4:	8556                	mv	a0,s5
 4c6:	00000097          	auipc	ra,0x0
 4ca:	e92080e7          	jalr	-366(ra) # 358 <putc>
        putc(fd, c);
 4ce:	85ca                	mv	a1,s2
 4d0:	8556                	mv	a0,s5
 4d2:	00000097          	auipc	ra,0x0
 4d6:	e86080e7          	jalr	-378(ra) # 358 <putc>
      }
      state = 0;
 4da:	4981                	li	s3,0
 4dc:	b765                	j	484 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 4de:	008b0913          	addi	s2,s6,8
 4e2:	4685                	li	a3,1
 4e4:	4629                	li	a2,10
 4e6:	000b2583          	lw	a1,0(s6)
 4ea:	8556                	mv	a0,s5
 4ec:	00000097          	auipc	ra,0x0
 4f0:	e8e080e7          	jalr	-370(ra) # 37a <printint>
 4f4:	8b4a                	mv	s6,s2
      state = 0;
 4f6:	4981                	li	s3,0
 4f8:	b771                	j	484 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4fa:	008b0913          	addi	s2,s6,8
 4fe:	4681                	li	a3,0
 500:	4629                	li	a2,10
 502:	000b2583          	lw	a1,0(s6)
 506:	8556                	mv	a0,s5
 508:	00000097          	auipc	ra,0x0
 50c:	e72080e7          	jalr	-398(ra) # 37a <printint>
 510:	8b4a                	mv	s6,s2
      state = 0;
 512:	4981                	li	s3,0
 514:	bf85                	j	484 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 516:	008b0913          	addi	s2,s6,8
 51a:	4681                	li	a3,0
 51c:	4641                	li	a2,16
 51e:	000b2583          	lw	a1,0(s6)
 522:	8556                	mv	a0,s5
 524:	00000097          	auipc	ra,0x0
 528:	e56080e7          	jalr	-426(ra) # 37a <printint>
 52c:	8b4a                	mv	s6,s2
      state = 0;
 52e:	4981                	li	s3,0
 530:	bf91                	j	484 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 532:	008b0793          	addi	a5,s6,8
 536:	f8f43423          	sd	a5,-120(s0)
 53a:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 53e:	03000593          	li	a1,48
 542:	8556                	mv	a0,s5
 544:	00000097          	auipc	ra,0x0
 548:	e14080e7          	jalr	-492(ra) # 358 <putc>
  putc(fd, 'x');
 54c:	85ea                	mv	a1,s10
 54e:	8556                	mv	a0,s5
 550:	00000097          	auipc	ra,0x0
 554:	e08080e7          	jalr	-504(ra) # 358 <putc>
 558:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 55a:	03c9d793          	srli	a5,s3,0x3c
 55e:	97de                	add	a5,a5,s7
 560:	0007c583          	lbu	a1,0(a5)
 564:	8556                	mv	a0,s5
 566:	00000097          	auipc	ra,0x0
 56a:	df2080e7          	jalr	-526(ra) # 358 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 56e:	0992                	slli	s3,s3,0x4
 570:	397d                	addiw	s2,s2,-1
 572:	fe0914e3          	bnez	s2,55a <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 576:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 57a:	4981                	li	s3,0
 57c:	b721                	j	484 <vprintf+0x60>
        s = va_arg(ap, char*);
 57e:	008b0993          	addi	s3,s6,8
 582:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 586:	02090163          	beqz	s2,5a8 <vprintf+0x184>
        while(*s != 0){
 58a:	00094583          	lbu	a1,0(s2)
 58e:	c9a1                	beqz	a1,5de <vprintf+0x1ba>
          putc(fd, *s);
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	dc6080e7          	jalr	-570(ra) # 358 <putc>
          s++;
 59a:	0905                	addi	s2,s2,1
        while(*s != 0){
 59c:	00094583          	lbu	a1,0(s2)
 5a0:	f9e5                	bnez	a1,590 <vprintf+0x16c>
        s = va_arg(ap, char*);
 5a2:	8b4e                	mv	s6,s3
      state = 0;
 5a4:	4981                	li	s3,0
 5a6:	bdf9                	j	484 <vprintf+0x60>
          s = "(null)";
 5a8:	00000917          	auipc	s2,0x0
 5ac:	23090913          	addi	s2,s2,560 # 7d8 <malloc+0xea>
        while(*s != 0){
 5b0:	02800593          	li	a1,40
 5b4:	bff1                	j	590 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5b6:	008b0913          	addi	s2,s6,8
 5ba:	000b4583          	lbu	a1,0(s6)
 5be:	8556                	mv	a0,s5
 5c0:	00000097          	auipc	ra,0x0
 5c4:	d98080e7          	jalr	-616(ra) # 358 <putc>
 5c8:	8b4a                	mv	s6,s2
      state = 0;
 5ca:	4981                	li	s3,0
 5cc:	bd65                	j	484 <vprintf+0x60>
        putc(fd, c);
 5ce:	85d2                	mv	a1,s4
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	d86080e7          	jalr	-634(ra) # 358 <putc>
      state = 0;
 5da:	4981                	li	s3,0
 5dc:	b565                	j	484 <vprintf+0x60>
        s = va_arg(ap, char*);
 5de:	8b4e                	mv	s6,s3
      state = 0;
 5e0:	4981                	li	s3,0
 5e2:	b54d                	j	484 <vprintf+0x60>
    }
  }
}
 5e4:	70e6                	ld	ra,120(sp)
 5e6:	7446                	ld	s0,112(sp)
 5e8:	74a6                	ld	s1,104(sp)
 5ea:	7906                	ld	s2,96(sp)
 5ec:	69e6                	ld	s3,88(sp)
 5ee:	6a46                	ld	s4,80(sp)
 5f0:	6aa6                	ld	s5,72(sp)
 5f2:	6b06                	ld	s6,64(sp)
 5f4:	7be2                	ld	s7,56(sp)
 5f6:	7c42                	ld	s8,48(sp)
 5f8:	7ca2                	ld	s9,40(sp)
 5fa:	7d02                	ld	s10,32(sp)
 5fc:	6de2                	ld	s11,24(sp)
 5fe:	6109                	addi	sp,sp,128
 600:	8082                	ret

0000000000000602 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 602:	715d                	addi	sp,sp,-80
 604:	ec06                	sd	ra,24(sp)
 606:	e822                	sd	s0,16(sp)
 608:	1000                	addi	s0,sp,32
 60a:	e010                	sd	a2,0(s0)
 60c:	e414                	sd	a3,8(s0)
 60e:	e818                	sd	a4,16(s0)
 610:	ec1c                	sd	a5,24(s0)
 612:	03043023          	sd	a6,32(s0)
 616:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 61a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 61e:	8622                	mv	a2,s0
 620:	00000097          	auipc	ra,0x0
 624:	e04080e7          	jalr	-508(ra) # 424 <vprintf>
}
 628:	60e2                	ld	ra,24(sp)
 62a:	6442                	ld	s0,16(sp)
 62c:	6161                	addi	sp,sp,80
 62e:	8082                	ret

0000000000000630 <printf>:

void
printf(const char *fmt, ...)
{
 630:	711d                	addi	sp,sp,-96
 632:	ec06                	sd	ra,24(sp)
 634:	e822                	sd	s0,16(sp)
 636:	1000                	addi	s0,sp,32
 638:	e40c                	sd	a1,8(s0)
 63a:	e810                	sd	a2,16(s0)
 63c:	ec14                	sd	a3,24(s0)
 63e:	f018                	sd	a4,32(s0)
 640:	f41c                	sd	a5,40(s0)
 642:	03043823          	sd	a6,48(s0)
 646:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 64a:	00840613          	addi	a2,s0,8
 64e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 652:	85aa                	mv	a1,a0
 654:	4505                	li	a0,1
 656:	00000097          	auipc	ra,0x0
 65a:	dce080e7          	jalr	-562(ra) # 424 <vprintf>
}
 65e:	60e2                	ld	ra,24(sp)
 660:	6442                	ld	s0,16(sp)
 662:	6125                	addi	sp,sp,96
 664:	8082                	ret

0000000000000666 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 666:	1141                	addi	sp,sp,-16
 668:	e422                	sd	s0,8(sp)
 66a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 66c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 670:	00000797          	auipc	a5,0x0
 674:	1887b783          	ld	a5,392(a5) # 7f8 <freep>
 678:	a805                	j	6a8 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 67a:	4618                	lw	a4,8(a2)
 67c:	9db9                	addw	a1,a1,a4
 67e:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 682:	6398                	ld	a4,0(a5)
 684:	6318                	ld	a4,0(a4)
 686:	fee53823          	sd	a4,-16(a0)
 68a:	a091                	j	6ce <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 68c:	ff852703          	lw	a4,-8(a0)
 690:	9e39                	addw	a2,a2,a4
 692:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 694:	ff053703          	ld	a4,-16(a0)
 698:	e398                	sd	a4,0(a5)
 69a:	a099                	j	6e0 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 69c:	6398                	ld	a4,0(a5)
 69e:	00e7e463          	bltu	a5,a4,6a6 <free+0x40>
 6a2:	00e6ea63          	bltu	a3,a4,6b6 <free+0x50>
{
 6a6:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a8:	fed7fae3          	bgeu	a5,a3,69c <free+0x36>
 6ac:	6398                	ld	a4,0(a5)
 6ae:	00e6e463          	bltu	a3,a4,6b6 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6b2:	fee7eae3          	bltu	a5,a4,6a6 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6b6:	ff852583          	lw	a1,-8(a0)
 6ba:	6390                	ld	a2,0(a5)
 6bc:	02059813          	slli	a6,a1,0x20
 6c0:	01c85713          	srli	a4,a6,0x1c
 6c4:	9736                	add	a4,a4,a3
 6c6:	fae60ae3          	beq	a2,a4,67a <free+0x14>
    bp->s.ptr = p->s.ptr;
 6ca:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6ce:	4790                	lw	a2,8(a5)
 6d0:	02061593          	slli	a1,a2,0x20
 6d4:	01c5d713          	srli	a4,a1,0x1c
 6d8:	973e                	add	a4,a4,a5
 6da:	fae689e3          	beq	a3,a4,68c <free+0x26>
  } else
    p->s.ptr = bp;
 6de:	e394                	sd	a3,0(a5)
  freep = p;
 6e0:	00000717          	auipc	a4,0x0
 6e4:	10f73c23          	sd	a5,280(a4) # 7f8 <freep>
}
 6e8:	6422                	ld	s0,8(sp)
 6ea:	0141                	addi	sp,sp,16
 6ec:	8082                	ret

00000000000006ee <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6ee:	7139                	addi	sp,sp,-64
 6f0:	fc06                	sd	ra,56(sp)
 6f2:	f822                	sd	s0,48(sp)
 6f4:	f426                	sd	s1,40(sp)
 6f6:	f04a                	sd	s2,32(sp)
 6f8:	ec4e                	sd	s3,24(sp)
 6fa:	e852                	sd	s4,16(sp)
 6fc:	e456                	sd	s5,8(sp)
 6fe:	e05a                	sd	s6,0(sp)
 700:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 702:	02051493          	slli	s1,a0,0x20
 706:	9081                	srli	s1,s1,0x20
 708:	04bd                	addi	s1,s1,15
 70a:	8091                	srli	s1,s1,0x4
 70c:	0014899b          	addiw	s3,s1,1
 710:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 712:	00000517          	auipc	a0,0x0
 716:	0e653503          	ld	a0,230(a0) # 7f8 <freep>
 71a:	c515                	beqz	a0,746 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 71c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 71e:	4798                	lw	a4,8(a5)
 720:	02977f63          	bgeu	a4,s1,75e <malloc+0x70>
 724:	8a4e                	mv	s4,s3
 726:	0009871b          	sext.w	a4,s3
 72a:	6685                	lui	a3,0x1
 72c:	00d77363          	bgeu	a4,a3,732 <malloc+0x44>
 730:	6a05                	lui	s4,0x1
 732:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 736:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 73a:	00000917          	auipc	s2,0x0
 73e:	0be90913          	addi	s2,s2,190 # 7f8 <freep>
  if(p == (char*)-1)
 742:	5afd                	li	s5,-1
 744:	a895                	j	7b8 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 746:	00000797          	auipc	a5,0x0
 74a:	0ba78793          	addi	a5,a5,186 # 800 <base>
 74e:	00000717          	auipc	a4,0x0
 752:	0af73523          	sd	a5,170(a4) # 7f8 <freep>
 756:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 758:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 75c:	b7e1                	j	724 <malloc+0x36>
      if(p->s.size == nunits)
 75e:	02e48c63          	beq	s1,a4,796 <malloc+0xa8>
        p->s.size -= nunits;
 762:	4137073b          	subw	a4,a4,s3
 766:	c798                	sw	a4,8(a5)
        p += p->s.size;
 768:	02071693          	slli	a3,a4,0x20
 76c:	01c6d713          	srli	a4,a3,0x1c
 770:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 772:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 776:	00000717          	auipc	a4,0x0
 77a:	08a73123          	sd	a0,130(a4) # 7f8 <freep>
      return (void*)(p + 1);
 77e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 782:	70e2                	ld	ra,56(sp)
 784:	7442                	ld	s0,48(sp)
 786:	74a2                	ld	s1,40(sp)
 788:	7902                	ld	s2,32(sp)
 78a:	69e2                	ld	s3,24(sp)
 78c:	6a42                	ld	s4,16(sp)
 78e:	6aa2                	ld	s5,8(sp)
 790:	6b02                	ld	s6,0(sp)
 792:	6121                	addi	sp,sp,64
 794:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 796:	6398                	ld	a4,0(a5)
 798:	e118                	sd	a4,0(a0)
 79a:	bff1                	j	776 <malloc+0x88>
  hp->s.size = nu;
 79c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7a0:	0541                	addi	a0,a0,16
 7a2:	00000097          	auipc	ra,0x0
 7a6:	ec4080e7          	jalr	-316(ra) # 666 <free>
  return freep;
 7aa:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7ae:	d971                	beqz	a0,782 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b2:	4798                	lw	a4,8(a5)
 7b4:	fa9775e3          	bgeu	a4,s1,75e <malloc+0x70>
    if(p == freep)
 7b8:	00093703          	ld	a4,0(s2)
 7bc:	853e                	mv	a0,a5
 7be:	fef719e3          	bne	a4,a5,7b0 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7c2:	8552                	mv	a0,s4
 7c4:	00000097          	auipc	ra,0x0
 7c8:	b6c080e7          	jalr	-1172(ra) # 330 <sbrk>
  if(p == (char*)-1)
 7cc:	fd5518e3          	bne	a0,s5,79c <malloc+0xae>
        return 0;
 7d0:	4501                	li	a0,0
 7d2:	bf45                	j	782 <malloc+0x94>
