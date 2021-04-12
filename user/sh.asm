
user/_sh:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <tryExecutingWithPaths>:
int fork1(void); // Fork but panics on failure.
void panic(char *);
struct cmd *parsecmd(char *);

void tryExecutingWithPaths(struct execcmd *ecmd)
{
       0:	bb010113          	addi	sp,sp,-1104
       4:	44113423          	sd	ra,1096(sp)
       8:	44813023          	sd	s0,1088(sp)
       c:	42913c23          	sd	s1,1080(sp)
      10:	43213823          	sd	s2,1072(sp)
      14:	43313423          	sd	s3,1064(sp)
      18:	43413023          	sd	s4,1056(sp)
      1c:	41513c23          	sd	s5,1048(sp)
      20:	41613823          	sd	s6,1040(sp)
      24:	41713423          	sd	s7,1032(sp)
      28:	41813023          	sd	s8,1024(sp)
      2c:	3f913c23          	sd	s9,1016(sp)
      30:	3fa13823          	sd	s10,1008(sp)
      34:	45010413          	addi	s0,sp,1104
      38:	8b2a                	mv	s6,a0
  int readChar;
  char buffer[1000];
  int pathFd;
  pathFd = open(PATH, O_RDONLY);
      3a:	4581                	li	a1,0
      3c:	00001517          	auipc	a0,0x1
      40:	41c50513          	addi	a0,a0,1052 # 1458 <malloc+0xe6>
      44:	00001097          	auipc	ra,0x1
      48:	f28080e7          	jalr	-216(ra) # f6c <open>
  if (pathFd == -1)
      4c:	57fd                	li	a5,-1
      4e:	02f50463          	beq	a0,a5,76 <tryExecutingWithPaths+0x76>
      52:	89aa                	mv	s3,a0
      54:	4481                	li	s1,0
    if (readChar == 0)
    {
      fprintf(2, "Reached end of path file\n");
      break;
    }
    if (buffer[i] == ':')
      56:	03a00a13          	li	s4,58
  for (int i = 0; i < 1000; i++)
      5a:	3e700a93          	li	s5,999
    {
      buffer[i] = '\000';
      fprintf(2, "Trying path: ");
      5e:	00001d17          	auipc	s10,0x1
      62:	442d0d13          	addi	s10,s10,1090 # 14a0 <malloc+0x12e>
      fprintf(2, buffer);
      fprintf(2, "\n");
      66:	00001c97          	auipc	s9,0x1
      6a:	432c8c93          	addi	s9,s9,1074 # 1498 <malloc+0x126>
      strcpy(buffer+i, ecmd->argv[0]);
      exec(buffer, ecmd->argv);
      6e:	008b0c13          	addi	s8,s6,8
  for (int i = 0; i < 1000; i++)
      72:	4b81                	li	s7,0
      74:	a87d                	j	132 <tryExecutingWithPaths+0x132>
    fprintf(2, "error opening path file\n");
      76:	00001597          	auipc	a1,0x1
      7a:	3ea58593          	addi	a1,a1,1002 # 1460 <malloc+0xee>
      7e:	4509                	li	a0,2
      80:	00001097          	auipc	ra,0x1
      84:	206080e7          	jalr	518(ra) # 1286 <fprintf>
    exit(1);
      88:	4505                	li	a0,1
      8a:	00001097          	auipc	ra,0x1
      8e:	ea2080e7          	jalr	-350(ra) # f2c <exit>
      fprintf(2, "Reached end of path file\n");
      92:	00001597          	auipc	a1,0x1
      96:	3ee58593          	addi	a1,a1,1006 # 1480 <malloc+0x10e>
      9a:	4509                	li	a0,2
      9c:	00001097          	auipc	ra,0x1
      a0:	1ea080e7          	jalr	490(ra) # 1286 <fprintf>
      i = -1;
    }
  }
  close(pathFd);
      a4:	854e                	mv	a0,s3
      a6:	00001097          	auipc	ra,0x1
      aa:	eae080e7          	jalr	-338(ra) # f54 <close>
}
      ae:	44813083          	ld	ra,1096(sp)
      b2:	44013403          	ld	s0,1088(sp)
      b6:	43813483          	ld	s1,1080(sp)
      ba:	43013903          	ld	s2,1072(sp)
      be:	42813983          	ld	s3,1064(sp)
      c2:	42013a03          	ld	s4,1056(sp)
      c6:	41813a83          	ld	s5,1048(sp)
      ca:	41013b03          	ld	s6,1040(sp)
      ce:	40813b83          	ld	s7,1032(sp)
      d2:	40013c03          	ld	s8,1024(sp)
      d6:	3f813c83          	ld	s9,1016(sp)
      da:	3f013d03          	ld	s10,1008(sp)
      de:	45010113          	addi	sp,sp,1104
      e2:	8082                	ret
      buffer[i] = '\000';
      e4:	fa040793          	addi	a5,s0,-96
      e8:	94be                	add	s1,s1,a5
      ea:	c0048c23          	sb	zero,-1000(s1)
      fprintf(2, "Trying path: ");
      ee:	85ea                	mv	a1,s10
      f0:	4509                	li	a0,2
      f2:	00001097          	auipc	ra,0x1
      f6:	194080e7          	jalr	404(ra) # 1286 <fprintf>
      fprintf(2, buffer);
      fa:	bb840593          	addi	a1,s0,-1096
      fe:	4509                	li	a0,2
     100:	00001097          	auipc	ra,0x1
     104:	186080e7          	jalr	390(ra) # 1286 <fprintf>
      fprintf(2, "\n");
     108:	85e6                	mv	a1,s9
     10a:	4509                	li	a0,2
     10c:	00001097          	auipc	ra,0x1
     110:	17a080e7          	jalr	378(ra) # 1286 <fprintf>
      strcpy(buffer+i, ecmd->argv[0]);
     114:	008b3583          	ld	a1,8(s6)
     118:	854a                	mv	a0,s2
     11a:	00001097          	auipc	ra,0x1
     11e:	ba4080e7          	jalr	-1116(ra) # cbe <strcpy>
      exec(buffer, ecmd->argv);
     122:	85e2                	mv	a1,s8
     124:	bb840513          	addi	a0,s0,-1096
     128:	00001097          	auipc	ra,0x1
     12c:	e3c080e7          	jalr	-452(ra) # f64 <exec>
  for (int i = 0; i < 1000; i++)
     130:	84de                	mv	s1,s7
    readChar = read(pathFd, buffer + i, 1);
     132:	bb840793          	addi	a5,s0,-1096
     136:	00978933          	add	s2,a5,s1
     13a:	4605                	li	a2,1
     13c:	85ca                	mv	a1,s2
     13e:	854e                	mv	a0,s3
     140:	00001097          	auipc	ra,0x1
     144:	e04080e7          	jalr	-508(ra) # f44 <read>
    if (readChar == 0)
     148:	d529                	beqz	a0,92 <tryExecutingWithPaths+0x92>
    if (buffer[i] == ':')
     14a:	fa040793          	addi	a5,s0,-96
     14e:	97a6                	add	a5,a5,s1
     150:	c187c783          	lbu	a5,-1000(a5)
     154:	f94788e3          	beq	a5,s4,e4 <tryExecutingWithPaths+0xe4>
  for (int i = 0; i < 1000; i++)
     158:	2485                	addiw	s1,s1,1
     15a:	fc9adce3          	bge	s5,s1,132 <tryExecutingWithPaths+0x132>
     15e:	b799                	j	a4 <tryExecutingWithPaths+0xa4>

0000000000000160 <getcmd>:
  }
  exit(0);
}

int getcmd(char *buf, int nbuf)
{
     160:	1101                	addi	sp,sp,-32
     162:	ec06                	sd	ra,24(sp)
     164:	e822                	sd	s0,16(sp)
     166:	e426                	sd	s1,8(sp)
     168:	e04a                	sd	s2,0(sp)
     16a:	1000                	addi	s0,sp,32
     16c:	84aa                	mv	s1,a0
     16e:	892e                	mv	s2,a1
  fprintf(2, "$ ");
     170:	00001597          	auipc	a1,0x1
     174:	34058593          	addi	a1,a1,832 # 14b0 <malloc+0x13e>
     178:	4509                	li	a0,2
     17a:	00001097          	auipc	ra,0x1
     17e:	10c080e7          	jalr	268(ra) # 1286 <fprintf>
  memset(buf, 0, nbuf);
     182:	864a                	mv	a2,s2
     184:	4581                	li	a1,0
     186:	8526                	mv	a0,s1
     188:	00001097          	auipc	ra,0x1
     18c:	ba8080e7          	jalr	-1112(ra) # d30 <memset>
  gets(buf, nbuf);
     190:	85ca                	mv	a1,s2
     192:	8526                	mv	a0,s1
     194:	00001097          	auipc	ra,0x1
     198:	be2080e7          	jalr	-1054(ra) # d76 <gets>
  if (buf[0] == 0) // EOF
     19c:	0004c503          	lbu	a0,0(s1)
     1a0:	00153513          	seqz	a0,a0
    return -1;
  return 0;
}
     1a4:	40a00533          	neg	a0,a0
     1a8:	60e2                	ld	ra,24(sp)
     1aa:	6442                	ld	s0,16(sp)
     1ac:	64a2                	ld	s1,8(sp)
     1ae:	6902                	ld	s2,0(sp)
     1b0:	6105                	addi	sp,sp,32
     1b2:	8082                	ret

00000000000001b4 <panic>:
  }
  exit(0);
}

void panic(char *s)
{
     1b4:	1141                	addi	sp,sp,-16
     1b6:	e406                	sd	ra,8(sp)
     1b8:	e022                	sd	s0,0(sp)
     1ba:	0800                	addi	s0,sp,16
     1bc:	862a                	mv	a2,a0
  fprintf(2, "%s\n", s);
     1be:	00001597          	auipc	a1,0x1
     1c2:	2fa58593          	addi	a1,a1,762 # 14b8 <malloc+0x146>
     1c6:	4509                	li	a0,2
     1c8:	00001097          	auipc	ra,0x1
     1cc:	0be080e7          	jalr	190(ra) # 1286 <fprintf>
  exit(1);
     1d0:	4505                	li	a0,1
     1d2:	00001097          	auipc	ra,0x1
     1d6:	d5a080e7          	jalr	-678(ra) # f2c <exit>

00000000000001da <fork1>:
}

int fork1(void)
{
     1da:	1141                	addi	sp,sp,-16
     1dc:	e406                	sd	ra,8(sp)
     1de:	e022                	sd	s0,0(sp)
     1e0:	0800                	addi	s0,sp,16
  int pid;

  pid = fork();
     1e2:	00001097          	auipc	ra,0x1
     1e6:	d42080e7          	jalr	-702(ra) # f24 <fork>
  if (pid == -1)
     1ea:	57fd                	li	a5,-1
     1ec:	00f50663          	beq	a0,a5,1f8 <fork1+0x1e>
    panic("fork");
  return pid;
}
     1f0:	60a2                	ld	ra,8(sp)
     1f2:	6402                	ld	s0,0(sp)
     1f4:	0141                	addi	sp,sp,16
     1f6:	8082                	ret
    panic("fork");
     1f8:	00001517          	auipc	a0,0x1
     1fc:	2c850513          	addi	a0,a0,712 # 14c0 <malloc+0x14e>
     200:	00000097          	auipc	ra,0x0
     204:	fb4080e7          	jalr	-76(ra) # 1b4 <panic>

0000000000000208 <runcmd>:
{
     208:	7179                	addi	sp,sp,-48
     20a:	f406                	sd	ra,40(sp)
     20c:	f022                	sd	s0,32(sp)
     20e:	ec26                	sd	s1,24(sp)
     210:	1800                	addi	s0,sp,48
  if (cmd == 0)
     212:	c10d                	beqz	a0,234 <runcmd+0x2c>
     214:	84aa                	mv	s1,a0
  switch (cmd->type)
     216:	4118                	lw	a4,0(a0)
     218:	4795                	li	a5,5
     21a:	02e7e263          	bltu	a5,a4,23e <runcmd+0x36>
     21e:	00056783          	lwu	a5,0(a0)
     222:	078a                	slli	a5,a5,0x2
     224:	00001717          	auipc	a4,0x1
     228:	39470713          	addi	a4,a4,916 # 15b8 <malloc+0x246>
     22c:	97ba                	add	a5,a5,a4
     22e:	439c                	lw	a5,0(a5)
     230:	97ba                	add	a5,a5,a4
     232:	8782                	jr	a5
    exit(1);
     234:	4505                	li	a0,1
     236:	00001097          	auipc	ra,0x1
     23a:	cf6080e7          	jalr	-778(ra) # f2c <exit>
    panic("runcmd");
     23e:	00001517          	auipc	a0,0x1
     242:	28a50513          	addi	a0,a0,650 # 14c8 <malloc+0x156>
     246:	00000097          	auipc	ra,0x0
     24a:	f6e080e7          	jalr	-146(ra) # 1b4 <panic>
    if (ecmd->argv[0] == 0)
     24e:	6508                	ld	a0,8(a0)
     250:	c91d                	beqz	a0,286 <runcmd+0x7e>
    exec(ecmd->argv[0], ecmd->argv);
     252:	00848593          	addi	a1,s1,8
     256:	00001097          	auipc	ra,0x1
     25a:	d0e080e7          	jalr	-754(ra) # f64 <exec>
    tryExecutingWithPaths(ecmd);
     25e:	8526                	mv	a0,s1
     260:	00000097          	auipc	ra,0x0
     264:	da0080e7          	jalr	-608(ra) # 0 <tryExecutingWithPaths>
    fprintf(2, "exec %s failed\n", ecmd->argv[0]);
     268:	6490                	ld	a2,8(s1)
     26a:	00001597          	auipc	a1,0x1
     26e:	26658593          	addi	a1,a1,614 # 14d0 <malloc+0x15e>
     272:	4509                	li	a0,2
     274:	00001097          	auipc	ra,0x1
     278:	012080e7          	jalr	18(ra) # 1286 <fprintf>
  exit(0);
     27c:	4501                	li	a0,0
     27e:	00001097          	auipc	ra,0x1
     282:	cae080e7          	jalr	-850(ra) # f2c <exit>
      exit(1);
     286:	4505                	li	a0,1
     288:	00001097          	auipc	ra,0x1
     28c:	ca4080e7          	jalr	-860(ra) # f2c <exit>
    close(rcmd->fd);
     290:	5148                	lw	a0,36(a0)
     292:	00001097          	auipc	ra,0x1
     296:	cc2080e7          	jalr	-830(ra) # f54 <close>
    if (open(rcmd->file, rcmd->mode) < 0)
     29a:	508c                	lw	a1,32(s1)
     29c:	6888                	ld	a0,16(s1)
     29e:	00001097          	auipc	ra,0x1
     2a2:	cce080e7          	jalr	-818(ra) # f6c <open>
     2a6:	00054763          	bltz	a0,2b4 <runcmd+0xac>
    runcmd(rcmd->cmd);
     2aa:	6488                	ld	a0,8(s1)
     2ac:	00000097          	auipc	ra,0x0
     2b0:	f5c080e7          	jalr	-164(ra) # 208 <runcmd>
      fprintf(2, "open %s failed\n", rcmd->file);
     2b4:	6890                	ld	a2,16(s1)
     2b6:	00001597          	auipc	a1,0x1
     2ba:	22a58593          	addi	a1,a1,554 # 14e0 <malloc+0x16e>
     2be:	4509                	li	a0,2
     2c0:	00001097          	auipc	ra,0x1
     2c4:	fc6080e7          	jalr	-58(ra) # 1286 <fprintf>
      exit(1);
     2c8:	4505                	li	a0,1
     2ca:	00001097          	auipc	ra,0x1
     2ce:	c62080e7          	jalr	-926(ra) # f2c <exit>
    if (fork1() == 0)
     2d2:	00000097          	auipc	ra,0x0
     2d6:	f08080e7          	jalr	-248(ra) # 1da <fork1>
     2da:	c919                	beqz	a0,2f0 <runcmd+0xe8>
    wait(0);
     2dc:	4501                	li	a0,0
     2de:	00001097          	auipc	ra,0x1
     2e2:	c56080e7          	jalr	-938(ra) # f34 <wait>
    runcmd(lcmd->right);
     2e6:	6888                	ld	a0,16(s1)
     2e8:	00000097          	auipc	ra,0x0
     2ec:	f20080e7          	jalr	-224(ra) # 208 <runcmd>
      runcmd(lcmd->left);
     2f0:	6488                	ld	a0,8(s1)
     2f2:	00000097          	auipc	ra,0x0
     2f6:	f16080e7          	jalr	-234(ra) # 208 <runcmd>
    if (pipe(p) < 0)
     2fa:	fd840513          	addi	a0,s0,-40
     2fe:	00001097          	auipc	ra,0x1
     302:	c3e080e7          	jalr	-962(ra) # f3c <pipe>
     306:	04054363          	bltz	a0,34c <runcmd+0x144>
    if (fork1() == 0)
     30a:	00000097          	auipc	ra,0x0
     30e:	ed0080e7          	jalr	-304(ra) # 1da <fork1>
     312:	c529                	beqz	a0,35c <runcmd+0x154>
    if (fork1() == 0)
     314:	00000097          	auipc	ra,0x0
     318:	ec6080e7          	jalr	-314(ra) # 1da <fork1>
     31c:	cd25                	beqz	a0,394 <runcmd+0x18c>
    close(p[0]);
     31e:	fd842503          	lw	a0,-40(s0)
     322:	00001097          	auipc	ra,0x1
     326:	c32080e7          	jalr	-974(ra) # f54 <close>
    close(p[1]);
     32a:	fdc42503          	lw	a0,-36(s0)
     32e:	00001097          	auipc	ra,0x1
     332:	c26080e7          	jalr	-986(ra) # f54 <close>
    wait(0);
     336:	4501                	li	a0,0
     338:	00001097          	auipc	ra,0x1
     33c:	bfc080e7          	jalr	-1028(ra) # f34 <wait>
    wait(0);
     340:	4501                	li	a0,0
     342:	00001097          	auipc	ra,0x1
     346:	bf2080e7          	jalr	-1038(ra) # f34 <wait>
    break;
     34a:	bf0d                	j	27c <runcmd+0x74>
      panic("pipe");
     34c:	00001517          	auipc	a0,0x1
     350:	1a450513          	addi	a0,a0,420 # 14f0 <malloc+0x17e>
     354:	00000097          	auipc	ra,0x0
     358:	e60080e7          	jalr	-416(ra) # 1b4 <panic>
      close(1);
     35c:	4505                	li	a0,1
     35e:	00001097          	auipc	ra,0x1
     362:	bf6080e7          	jalr	-1034(ra) # f54 <close>
      dup(p[1]);
     366:	fdc42503          	lw	a0,-36(s0)
     36a:	00001097          	auipc	ra,0x1
     36e:	c3a080e7          	jalr	-966(ra) # fa4 <dup>
      close(p[0]);
     372:	fd842503          	lw	a0,-40(s0)
     376:	00001097          	auipc	ra,0x1
     37a:	bde080e7          	jalr	-1058(ra) # f54 <close>
      close(p[1]);
     37e:	fdc42503          	lw	a0,-36(s0)
     382:	00001097          	auipc	ra,0x1
     386:	bd2080e7          	jalr	-1070(ra) # f54 <close>
      runcmd(pcmd->left);
     38a:	6488                	ld	a0,8(s1)
     38c:	00000097          	auipc	ra,0x0
     390:	e7c080e7          	jalr	-388(ra) # 208 <runcmd>
      close(0);
     394:	00001097          	auipc	ra,0x1
     398:	bc0080e7          	jalr	-1088(ra) # f54 <close>
      dup(p[0]);
     39c:	fd842503          	lw	a0,-40(s0)
     3a0:	00001097          	auipc	ra,0x1
     3a4:	c04080e7          	jalr	-1020(ra) # fa4 <dup>
      close(p[0]);
     3a8:	fd842503          	lw	a0,-40(s0)
     3ac:	00001097          	auipc	ra,0x1
     3b0:	ba8080e7          	jalr	-1112(ra) # f54 <close>
      close(p[1]);
     3b4:	fdc42503          	lw	a0,-36(s0)
     3b8:	00001097          	auipc	ra,0x1
     3bc:	b9c080e7          	jalr	-1124(ra) # f54 <close>
      runcmd(pcmd->right);
     3c0:	6888                	ld	a0,16(s1)
     3c2:	00000097          	auipc	ra,0x0
     3c6:	e46080e7          	jalr	-442(ra) # 208 <runcmd>
    if (fork1() == 0)
     3ca:	00000097          	auipc	ra,0x0
     3ce:	e10080e7          	jalr	-496(ra) # 1da <fork1>
     3d2:	ea0515e3          	bnez	a0,27c <runcmd+0x74>
      runcmd(bcmd->cmd);
     3d6:	6488                	ld	a0,8(s1)
     3d8:	00000097          	auipc	ra,0x0
     3dc:	e30080e7          	jalr	-464(ra) # 208 <runcmd>

00000000000003e0 <execcmd>:
//PAGEBREAK!
// Constructors

struct cmd *
execcmd(void)
{
     3e0:	1101                	addi	sp,sp,-32
     3e2:	ec06                	sd	ra,24(sp)
     3e4:	e822                	sd	s0,16(sp)
     3e6:	e426                	sd	s1,8(sp)
     3e8:	1000                	addi	s0,sp,32
  struct execcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     3ea:	0a800513          	li	a0,168
     3ee:	00001097          	auipc	ra,0x1
     3f2:	f84080e7          	jalr	-124(ra) # 1372 <malloc>
     3f6:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     3f8:	0a800613          	li	a2,168
     3fc:	4581                	li	a1,0
     3fe:	00001097          	auipc	ra,0x1
     402:	932080e7          	jalr	-1742(ra) # d30 <memset>
  cmd->type = EXEC;
     406:	4785                	li	a5,1
     408:	c09c                	sw	a5,0(s1)
  return (struct cmd *)cmd;
}
     40a:	8526                	mv	a0,s1
     40c:	60e2                	ld	ra,24(sp)
     40e:	6442                	ld	s0,16(sp)
     410:	64a2                	ld	s1,8(sp)
     412:	6105                	addi	sp,sp,32
     414:	8082                	ret

0000000000000416 <redircmd>:

struct cmd *
redircmd(struct cmd *subcmd, char *file, char *efile, int mode, int fd)
{
     416:	7139                	addi	sp,sp,-64
     418:	fc06                	sd	ra,56(sp)
     41a:	f822                	sd	s0,48(sp)
     41c:	f426                	sd	s1,40(sp)
     41e:	f04a                	sd	s2,32(sp)
     420:	ec4e                	sd	s3,24(sp)
     422:	e852                	sd	s4,16(sp)
     424:	e456                	sd	s5,8(sp)
     426:	e05a                	sd	s6,0(sp)
     428:	0080                	addi	s0,sp,64
     42a:	8b2a                	mv	s6,a0
     42c:	8aae                	mv	s5,a1
     42e:	8a32                	mv	s4,a2
     430:	89b6                	mv	s3,a3
     432:	893a                	mv	s2,a4
  struct redircmd *cmd;

  cmd = malloc(sizeof(*cmd));
     434:	02800513          	li	a0,40
     438:	00001097          	auipc	ra,0x1
     43c:	f3a080e7          	jalr	-198(ra) # 1372 <malloc>
     440:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     442:	02800613          	li	a2,40
     446:	4581                	li	a1,0
     448:	00001097          	auipc	ra,0x1
     44c:	8e8080e7          	jalr	-1816(ra) # d30 <memset>
  cmd->type = REDIR;
     450:	4789                	li	a5,2
     452:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     454:	0164b423          	sd	s6,8(s1)
  cmd->file = file;
     458:	0154b823          	sd	s5,16(s1)
  cmd->efile = efile;
     45c:	0144bc23          	sd	s4,24(s1)
  cmd->mode = mode;
     460:	0334a023          	sw	s3,32(s1)
  cmd->fd = fd;
     464:	0324a223          	sw	s2,36(s1)
  return (struct cmd *)cmd;
}
     468:	8526                	mv	a0,s1
     46a:	70e2                	ld	ra,56(sp)
     46c:	7442                	ld	s0,48(sp)
     46e:	74a2                	ld	s1,40(sp)
     470:	7902                	ld	s2,32(sp)
     472:	69e2                	ld	s3,24(sp)
     474:	6a42                	ld	s4,16(sp)
     476:	6aa2                	ld	s5,8(sp)
     478:	6b02                	ld	s6,0(sp)
     47a:	6121                	addi	sp,sp,64
     47c:	8082                	ret

000000000000047e <pipecmd>:

struct cmd *
pipecmd(struct cmd *left, struct cmd *right)
{
     47e:	7179                	addi	sp,sp,-48
     480:	f406                	sd	ra,40(sp)
     482:	f022                	sd	s0,32(sp)
     484:	ec26                	sd	s1,24(sp)
     486:	e84a                	sd	s2,16(sp)
     488:	e44e                	sd	s3,8(sp)
     48a:	1800                	addi	s0,sp,48
     48c:	89aa                	mv	s3,a0
     48e:	892e                	mv	s2,a1
  struct pipecmd *cmd;

  cmd = malloc(sizeof(*cmd));
     490:	4561                	li	a0,24
     492:	00001097          	auipc	ra,0x1
     496:	ee0080e7          	jalr	-288(ra) # 1372 <malloc>
     49a:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     49c:	4661                	li	a2,24
     49e:	4581                	li	a1,0
     4a0:	00001097          	auipc	ra,0x1
     4a4:	890080e7          	jalr	-1904(ra) # d30 <memset>
  cmd->type = PIPE;
     4a8:	478d                	li	a5,3
     4aa:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     4ac:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     4b0:	0124b823          	sd	s2,16(s1)
  return (struct cmd *)cmd;
}
     4b4:	8526                	mv	a0,s1
     4b6:	70a2                	ld	ra,40(sp)
     4b8:	7402                	ld	s0,32(sp)
     4ba:	64e2                	ld	s1,24(sp)
     4bc:	6942                	ld	s2,16(sp)
     4be:	69a2                	ld	s3,8(sp)
     4c0:	6145                	addi	sp,sp,48
     4c2:	8082                	ret

00000000000004c4 <listcmd>:

struct cmd *
listcmd(struct cmd *left, struct cmd *right)
{
     4c4:	7179                	addi	sp,sp,-48
     4c6:	f406                	sd	ra,40(sp)
     4c8:	f022                	sd	s0,32(sp)
     4ca:	ec26                	sd	s1,24(sp)
     4cc:	e84a                	sd	s2,16(sp)
     4ce:	e44e                	sd	s3,8(sp)
     4d0:	1800                	addi	s0,sp,48
     4d2:	89aa                	mv	s3,a0
     4d4:	892e                	mv	s2,a1
  struct listcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     4d6:	4561                	li	a0,24
     4d8:	00001097          	auipc	ra,0x1
     4dc:	e9a080e7          	jalr	-358(ra) # 1372 <malloc>
     4e0:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     4e2:	4661                	li	a2,24
     4e4:	4581                	li	a1,0
     4e6:	00001097          	auipc	ra,0x1
     4ea:	84a080e7          	jalr	-1974(ra) # d30 <memset>
  cmd->type = LIST;
     4ee:	4791                	li	a5,4
     4f0:	c09c                	sw	a5,0(s1)
  cmd->left = left;
     4f2:	0134b423          	sd	s3,8(s1)
  cmd->right = right;
     4f6:	0124b823          	sd	s2,16(s1)
  return (struct cmd *)cmd;
}
     4fa:	8526                	mv	a0,s1
     4fc:	70a2                	ld	ra,40(sp)
     4fe:	7402                	ld	s0,32(sp)
     500:	64e2                	ld	s1,24(sp)
     502:	6942                	ld	s2,16(sp)
     504:	69a2                	ld	s3,8(sp)
     506:	6145                	addi	sp,sp,48
     508:	8082                	ret

000000000000050a <backcmd>:

struct cmd *
backcmd(struct cmd *subcmd)
{
     50a:	1101                	addi	sp,sp,-32
     50c:	ec06                	sd	ra,24(sp)
     50e:	e822                	sd	s0,16(sp)
     510:	e426                	sd	s1,8(sp)
     512:	e04a                	sd	s2,0(sp)
     514:	1000                	addi	s0,sp,32
     516:	892a                	mv	s2,a0
  struct backcmd *cmd;

  cmd = malloc(sizeof(*cmd));
     518:	4541                	li	a0,16
     51a:	00001097          	auipc	ra,0x1
     51e:	e58080e7          	jalr	-424(ra) # 1372 <malloc>
     522:	84aa                	mv	s1,a0
  memset(cmd, 0, sizeof(*cmd));
     524:	4641                	li	a2,16
     526:	4581                	li	a1,0
     528:	00001097          	auipc	ra,0x1
     52c:	808080e7          	jalr	-2040(ra) # d30 <memset>
  cmd->type = BACK;
     530:	4795                	li	a5,5
     532:	c09c                	sw	a5,0(s1)
  cmd->cmd = subcmd;
     534:	0124b423          	sd	s2,8(s1)
  return (struct cmd *)cmd;
}
     538:	8526                	mv	a0,s1
     53a:	60e2                	ld	ra,24(sp)
     53c:	6442                	ld	s0,16(sp)
     53e:	64a2                	ld	s1,8(sp)
     540:	6902                	ld	s2,0(sp)
     542:	6105                	addi	sp,sp,32
     544:	8082                	ret

0000000000000546 <gettoken>:

char whitespace[] = " \t\r\n\v";
char symbols[] = "<|>&;()";

int gettoken(char **ps, char *es, char **q, char **eq)
{
     546:	7139                	addi	sp,sp,-64
     548:	fc06                	sd	ra,56(sp)
     54a:	f822                	sd	s0,48(sp)
     54c:	f426                	sd	s1,40(sp)
     54e:	f04a                	sd	s2,32(sp)
     550:	ec4e                	sd	s3,24(sp)
     552:	e852                	sd	s4,16(sp)
     554:	e456                	sd	s5,8(sp)
     556:	e05a                	sd	s6,0(sp)
     558:	0080                	addi	s0,sp,64
     55a:	8a2a                	mv	s4,a0
     55c:	892e                	mv	s2,a1
     55e:	8ab2                	mv	s5,a2
     560:	8b36                	mv	s6,a3
  char *s;
  int ret;

  s = *ps;
     562:	6104                	ld	s1,0(a0)
  while (s < es && strchr(whitespace, *s))
     564:	00001997          	auipc	s3,0x1
     568:	0ac98993          	addi	s3,s3,172 # 1610 <whitespace>
     56c:	00b4fd63          	bgeu	s1,a1,586 <gettoken+0x40>
     570:	0004c583          	lbu	a1,0(s1)
     574:	854e                	mv	a0,s3
     576:	00000097          	auipc	ra,0x0
     57a:	7dc080e7          	jalr	2012(ra) # d52 <strchr>
     57e:	c501                	beqz	a0,586 <gettoken+0x40>
    s++;
     580:	0485                	addi	s1,s1,1
  while (s < es && strchr(whitespace, *s))
     582:	fe9917e3          	bne	s2,s1,570 <gettoken+0x2a>
  if (q)
     586:	000a8463          	beqz	s5,58e <gettoken+0x48>
    *q = s;
     58a:	009ab023          	sd	s1,0(s5)
  ret = *s;
     58e:	0004c783          	lbu	a5,0(s1)
     592:	00078a9b          	sext.w	s5,a5
  switch (*s)
     596:	03c00713          	li	a4,60
     59a:	06f76563          	bltu	a4,a5,604 <gettoken+0xbe>
     59e:	03a00713          	li	a4,58
     5a2:	00f76e63          	bltu	a4,a5,5be <gettoken+0x78>
     5a6:	cf89                	beqz	a5,5c0 <gettoken+0x7a>
     5a8:	02600713          	li	a4,38
     5ac:	00e78963          	beq	a5,a4,5be <gettoken+0x78>
     5b0:	fd87879b          	addiw	a5,a5,-40
     5b4:	0ff7f793          	andi	a5,a5,255
     5b8:	4705                	li	a4,1
     5ba:	06f76c63          	bltu	a4,a5,632 <gettoken+0xec>
  case '(':
  case ')':
  case ';':
  case '&':
  case '<':
    s++;
     5be:	0485                	addi	s1,s1,1
    ret = 'a';
    while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
      s++;
    break;
  }
  if (eq)
     5c0:	000b0463          	beqz	s6,5c8 <gettoken+0x82>
    *eq = s;
     5c4:	009b3023          	sd	s1,0(s6)

  while (s < es && strchr(whitespace, *s))
     5c8:	00001997          	auipc	s3,0x1
     5cc:	04898993          	addi	s3,s3,72 # 1610 <whitespace>
     5d0:	0124fd63          	bgeu	s1,s2,5ea <gettoken+0xa4>
     5d4:	0004c583          	lbu	a1,0(s1)
     5d8:	854e                	mv	a0,s3
     5da:	00000097          	auipc	ra,0x0
     5de:	778080e7          	jalr	1912(ra) # d52 <strchr>
     5e2:	c501                	beqz	a0,5ea <gettoken+0xa4>
    s++;
     5e4:	0485                	addi	s1,s1,1
  while (s < es && strchr(whitespace, *s))
     5e6:	fe9917e3          	bne	s2,s1,5d4 <gettoken+0x8e>
  *ps = s;
     5ea:	009a3023          	sd	s1,0(s4)
  return ret;
}
     5ee:	8556                	mv	a0,s5
     5f0:	70e2                	ld	ra,56(sp)
     5f2:	7442                	ld	s0,48(sp)
     5f4:	74a2                	ld	s1,40(sp)
     5f6:	7902                	ld	s2,32(sp)
     5f8:	69e2                	ld	s3,24(sp)
     5fa:	6a42                	ld	s4,16(sp)
     5fc:	6aa2                	ld	s5,8(sp)
     5fe:	6b02                	ld	s6,0(sp)
     600:	6121                	addi	sp,sp,64
     602:	8082                	ret
  switch (*s)
     604:	03e00713          	li	a4,62
     608:	02e79163          	bne	a5,a4,62a <gettoken+0xe4>
    s++;
     60c:	00148693          	addi	a3,s1,1
    if (*s == '>')
     610:	0014c703          	lbu	a4,1(s1)
     614:	03e00793          	li	a5,62
      s++;
     618:	0489                	addi	s1,s1,2
      ret = '+';
     61a:	02b00a93          	li	s5,43
    if (*s == '>')
     61e:	faf701e3          	beq	a4,a5,5c0 <gettoken+0x7a>
    s++;
     622:	84b6                	mv	s1,a3
  ret = *s;
     624:	03e00a93          	li	s5,62
     628:	bf61                	j	5c0 <gettoken+0x7a>
  switch (*s)
     62a:	07c00713          	li	a4,124
     62e:	f8e788e3          	beq	a5,a4,5be <gettoken+0x78>
    while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     632:	00001997          	auipc	s3,0x1
     636:	fde98993          	addi	s3,s3,-34 # 1610 <whitespace>
     63a:	00001a97          	auipc	s5,0x1
     63e:	fcea8a93          	addi	s5,s5,-50 # 1608 <symbols>
     642:	0324f563          	bgeu	s1,s2,66c <gettoken+0x126>
     646:	0004c583          	lbu	a1,0(s1)
     64a:	854e                	mv	a0,s3
     64c:	00000097          	auipc	ra,0x0
     650:	706080e7          	jalr	1798(ra) # d52 <strchr>
     654:	e505                	bnez	a0,67c <gettoken+0x136>
     656:	0004c583          	lbu	a1,0(s1)
     65a:	8556                	mv	a0,s5
     65c:	00000097          	auipc	ra,0x0
     660:	6f6080e7          	jalr	1782(ra) # d52 <strchr>
     664:	e909                	bnez	a0,676 <gettoken+0x130>
      s++;
     666:	0485                	addi	s1,s1,1
    while (s < es && !strchr(whitespace, *s) && !strchr(symbols, *s))
     668:	fc991fe3          	bne	s2,s1,646 <gettoken+0x100>
  if (eq)
     66c:	06100a93          	li	s5,97
     670:	f40b1ae3          	bnez	s6,5c4 <gettoken+0x7e>
     674:	bf9d                	j	5ea <gettoken+0xa4>
    ret = 'a';
     676:	06100a93          	li	s5,97
     67a:	b799                	j	5c0 <gettoken+0x7a>
     67c:	06100a93          	li	s5,97
     680:	b781                	j	5c0 <gettoken+0x7a>

0000000000000682 <peek>:

int peek(char **ps, char *es, char *toks)
{
     682:	7139                	addi	sp,sp,-64
     684:	fc06                	sd	ra,56(sp)
     686:	f822                	sd	s0,48(sp)
     688:	f426                	sd	s1,40(sp)
     68a:	f04a                	sd	s2,32(sp)
     68c:	ec4e                	sd	s3,24(sp)
     68e:	e852                	sd	s4,16(sp)
     690:	e456                	sd	s5,8(sp)
     692:	0080                	addi	s0,sp,64
     694:	8a2a                	mv	s4,a0
     696:	892e                	mv	s2,a1
     698:	8ab2                	mv	s5,a2
  char *s;

  s = *ps;
     69a:	6104                	ld	s1,0(a0)
  while (s < es && strchr(whitespace, *s))
     69c:	00001997          	auipc	s3,0x1
     6a0:	f7498993          	addi	s3,s3,-140 # 1610 <whitespace>
     6a4:	00b4fd63          	bgeu	s1,a1,6be <peek+0x3c>
     6a8:	0004c583          	lbu	a1,0(s1)
     6ac:	854e                	mv	a0,s3
     6ae:	00000097          	auipc	ra,0x0
     6b2:	6a4080e7          	jalr	1700(ra) # d52 <strchr>
     6b6:	c501                	beqz	a0,6be <peek+0x3c>
    s++;
     6b8:	0485                	addi	s1,s1,1
  while (s < es && strchr(whitespace, *s))
     6ba:	fe9917e3          	bne	s2,s1,6a8 <peek+0x26>
  *ps = s;
     6be:	009a3023          	sd	s1,0(s4)
  return *s && strchr(toks, *s);
     6c2:	0004c583          	lbu	a1,0(s1)
     6c6:	4501                	li	a0,0
     6c8:	e991                	bnez	a1,6dc <peek+0x5a>
}
     6ca:	70e2                	ld	ra,56(sp)
     6cc:	7442                	ld	s0,48(sp)
     6ce:	74a2                	ld	s1,40(sp)
     6d0:	7902                	ld	s2,32(sp)
     6d2:	69e2                	ld	s3,24(sp)
     6d4:	6a42                	ld	s4,16(sp)
     6d6:	6aa2                	ld	s5,8(sp)
     6d8:	6121                	addi	sp,sp,64
     6da:	8082                	ret
  return *s && strchr(toks, *s);
     6dc:	8556                	mv	a0,s5
     6de:	00000097          	auipc	ra,0x0
     6e2:	674080e7          	jalr	1652(ra) # d52 <strchr>
     6e6:	00a03533          	snez	a0,a0
     6ea:	b7c5                	j	6ca <peek+0x48>

00000000000006ec <parseredirs>:
  return cmd;
}

struct cmd *
parseredirs(struct cmd *cmd, char **ps, char *es)
{
     6ec:	7159                	addi	sp,sp,-112
     6ee:	f486                	sd	ra,104(sp)
     6f0:	f0a2                	sd	s0,96(sp)
     6f2:	eca6                	sd	s1,88(sp)
     6f4:	e8ca                	sd	s2,80(sp)
     6f6:	e4ce                	sd	s3,72(sp)
     6f8:	e0d2                	sd	s4,64(sp)
     6fa:	fc56                	sd	s5,56(sp)
     6fc:	f85a                	sd	s6,48(sp)
     6fe:	f45e                	sd	s7,40(sp)
     700:	f062                	sd	s8,32(sp)
     702:	ec66                	sd	s9,24(sp)
     704:	1880                	addi	s0,sp,112
     706:	8a2a                	mv	s4,a0
     708:	89ae                	mv	s3,a1
     70a:	8932                	mv	s2,a2
  int tok;
  char *q, *eq;

  while (peek(ps, es, "<>"))
     70c:	00001b97          	auipc	s7,0x1
     710:	e0cb8b93          	addi	s7,s7,-500 # 1518 <malloc+0x1a6>
  {
    tok = gettoken(ps, es, 0, 0);
    if (gettoken(ps, es, &q, &eq) != 'a')
     714:	06100c13          	li	s8,97
      panic("missing file for redirection");
    switch (tok)
     718:	03c00c93          	li	s9,60
  while (peek(ps, es, "<>"))
     71c:	a02d                	j	746 <parseredirs+0x5a>
      panic("missing file for redirection");
     71e:	00001517          	auipc	a0,0x1
     722:	dda50513          	addi	a0,a0,-550 # 14f8 <malloc+0x186>
     726:	00000097          	auipc	ra,0x0
     72a:	a8e080e7          	jalr	-1394(ra) # 1b4 <panic>
    {
    case '<':
      cmd = redircmd(cmd, q, eq, O_RDONLY, 0);
     72e:	4701                	li	a4,0
     730:	4681                	li	a3,0
     732:	f9043603          	ld	a2,-112(s0)
     736:	f9843583          	ld	a1,-104(s0)
     73a:	8552                	mv	a0,s4
     73c:	00000097          	auipc	ra,0x0
     740:	cda080e7          	jalr	-806(ra) # 416 <redircmd>
     744:	8a2a                	mv	s4,a0
    switch (tok)
     746:	03e00b13          	li	s6,62
     74a:	02b00a93          	li	s5,43
  while (peek(ps, es, "<>"))
     74e:	865e                	mv	a2,s7
     750:	85ca                	mv	a1,s2
     752:	854e                	mv	a0,s3
     754:	00000097          	auipc	ra,0x0
     758:	f2e080e7          	jalr	-210(ra) # 682 <peek>
     75c:	c925                	beqz	a0,7cc <parseredirs+0xe0>
    tok = gettoken(ps, es, 0, 0);
     75e:	4681                	li	a3,0
     760:	4601                	li	a2,0
     762:	85ca                	mv	a1,s2
     764:	854e                	mv	a0,s3
     766:	00000097          	auipc	ra,0x0
     76a:	de0080e7          	jalr	-544(ra) # 546 <gettoken>
     76e:	84aa                	mv	s1,a0
    if (gettoken(ps, es, &q, &eq) != 'a')
     770:	f9040693          	addi	a3,s0,-112
     774:	f9840613          	addi	a2,s0,-104
     778:	85ca                	mv	a1,s2
     77a:	854e                	mv	a0,s3
     77c:	00000097          	auipc	ra,0x0
     780:	dca080e7          	jalr	-566(ra) # 546 <gettoken>
     784:	f9851de3          	bne	a0,s8,71e <parseredirs+0x32>
    switch (tok)
     788:	fb9483e3          	beq	s1,s9,72e <parseredirs+0x42>
     78c:	03648263          	beq	s1,s6,7b0 <parseredirs+0xc4>
     790:	fb549fe3          	bne	s1,s5,74e <parseredirs+0x62>
      break;
    case '>':
      cmd = redircmd(cmd, q, eq, O_WRONLY | O_CREATE | O_TRUNC, 1);
      break;
    case '+': // >>
      cmd = redircmd(cmd, q, eq, O_WRONLY | O_CREATE, 1);
     794:	4705                	li	a4,1
     796:	20100693          	li	a3,513
     79a:	f9043603          	ld	a2,-112(s0)
     79e:	f9843583          	ld	a1,-104(s0)
     7a2:	8552                	mv	a0,s4
     7a4:	00000097          	auipc	ra,0x0
     7a8:	c72080e7          	jalr	-910(ra) # 416 <redircmd>
     7ac:	8a2a                	mv	s4,a0
      break;
     7ae:	bf61                	j	746 <parseredirs+0x5a>
      cmd = redircmd(cmd, q, eq, O_WRONLY | O_CREATE | O_TRUNC, 1);
     7b0:	4705                	li	a4,1
     7b2:	60100693          	li	a3,1537
     7b6:	f9043603          	ld	a2,-112(s0)
     7ba:	f9843583          	ld	a1,-104(s0)
     7be:	8552                	mv	a0,s4
     7c0:	00000097          	auipc	ra,0x0
     7c4:	c56080e7          	jalr	-938(ra) # 416 <redircmd>
     7c8:	8a2a                	mv	s4,a0
      break;
     7ca:	bfb5                	j	746 <parseredirs+0x5a>
    }
  }
  return cmd;
}
     7cc:	8552                	mv	a0,s4
     7ce:	70a6                	ld	ra,104(sp)
     7d0:	7406                	ld	s0,96(sp)
     7d2:	64e6                	ld	s1,88(sp)
     7d4:	6946                	ld	s2,80(sp)
     7d6:	69a6                	ld	s3,72(sp)
     7d8:	6a06                	ld	s4,64(sp)
     7da:	7ae2                	ld	s5,56(sp)
     7dc:	7b42                	ld	s6,48(sp)
     7de:	7ba2                	ld	s7,40(sp)
     7e0:	7c02                	ld	s8,32(sp)
     7e2:	6ce2                	ld	s9,24(sp)
     7e4:	6165                	addi	sp,sp,112
     7e6:	8082                	ret

00000000000007e8 <parseexec>:
  return cmd;
}

struct cmd *
parseexec(char **ps, char *es)
{
     7e8:	7159                	addi	sp,sp,-112
     7ea:	f486                	sd	ra,104(sp)
     7ec:	f0a2                	sd	s0,96(sp)
     7ee:	eca6                	sd	s1,88(sp)
     7f0:	e8ca                	sd	s2,80(sp)
     7f2:	e4ce                	sd	s3,72(sp)
     7f4:	e0d2                	sd	s4,64(sp)
     7f6:	fc56                	sd	s5,56(sp)
     7f8:	f85a                	sd	s6,48(sp)
     7fa:	f45e                	sd	s7,40(sp)
     7fc:	f062                	sd	s8,32(sp)
     7fe:	ec66                	sd	s9,24(sp)
     800:	1880                	addi	s0,sp,112
     802:	8a2a                	mv	s4,a0
     804:	8aae                	mv	s5,a1
  char *q, *eq;
  int tok, argc;
  struct execcmd *cmd;
  struct cmd *ret;

  if (peek(ps, es, "("))
     806:	00001617          	auipc	a2,0x1
     80a:	d1a60613          	addi	a2,a2,-742 # 1520 <malloc+0x1ae>
     80e:	00000097          	auipc	ra,0x0
     812:	e74080e7          	jalr	-396(ra) # 682 <peek>
     816:	e905                	bnez	a0,846 <parseexec+0x5e>
     818:	89aa                	mv	s3,a0
    return parseblock(ps, es);

  ret = execcmd();
     81a:	00000097          	auipc	ra,0x0
     81e:	bc6080e7          	jalr	-1082(ra) # 3e0 <execcmd>
     822:	8c2a                	mv	s8,a0
  cmd = (struct execcmd *)ret;

  argc = 0;
  ret = parseredirs(ret, ps, es);
     824:	8656                	mv	a2,s5
     826:	85d2                	mv	a1,s4
     828:	00000097          	auipc	ra,0x0
     82c:	ec4080e7          	jalr	-316(ra) # 6ec <parseredirs>
     830:	84aa                	mv	s1,a0
  while (!peek(ps, es, "|)&;"))
     832:	008c0913          	addi	s2,s8,8
     836:	00001b17          	auipc	s6,0x1
     83a:	d0ab0b13          	addi	s6,s6,-758 # 1540 <malloc+0x1ce>
  {
    if ((tok = gettoken(ps, es, &q, &eq)) == 0)
      break;
    if (tok != 'a')
     83e:	06100c93          	li	s9,97
      panic("syntax");
    cmd->argv[argc] = q;
    cmd->eargv[argc] = eq;
    argc++;
    if (argc >= MAXARGS)
     842:	4ba9                	li	s7,10
  while (!peek(ps, es, "|)&;"))
     844:	a0b1                	j	890 <parseexec+0xa8>
    return parseblock(ps, es);
     846:	85d6                	mv	a1,s5
     848:	8552                	mv	a0,s4
     84a:	00000097          	auipc	ra,0x0
     84e:	1bc080e7          	jalr	444(ra) # a06 <parseblock>
     852:	84aa                	mv	s1,a0
    ret = parseredirs(ret, ps, es);
  }
  cmd->argv[argc] = 0;
  cmd->eargv[argc] = 0;
  return ret;
}
     854:	8526                	mv	a0,s1
     856:	70a6                	ld	ra,104(sp)
     858:	7406                	ld	s0,96(sp)
     85a:	64e6                	ld	s1,88(sp)
     85c:	6946                	ld	s2,80(sp)
     85e:	69a6                	ld	s3,72(sp)
     860:	6a06                	ld	s4,64(sp)
     862:	7ae2                	ld	s5,56(sp)
     864:	7b42                	ld	s6,48(sp)
     866:	7ba2                	ld	s7,40(sp)
     868:	7c02                	ld	s8,32(sp)
     86a:	6ce2                	ld	s9,24(sp)
     86c:	6165                	addi	sp,sp,112
     86e:	8082                	ret
      panic("syntax");
     870:	00001517          	auipc	a0,0x1
     874:	cb850513          	addi	a0,a0,-840 # 1528 <malloc+0x1b6>
     878:	00000097          	auipc	ra,0x0
     87c:	93c080e7          	jalr	-1732(ra) # 1b4 <panic>
    ret = parseredirs(ret, ps, es);
     880:	8656                	mv	a2,s5
     882:	85d2                	mv	a1,s4
     884:	8526                	mv	a0,s1
     886:	00000097          	auipc	ra,0x0
     88a:	e66080e7          	jalr	-410(ra) # 6ec <parseredirs>
     88e:	84aa                	mv	s1,a0
  while (!peek(ps, es, "|)&;"))
     890:	865a                	mv	a2,s6
     892:	85d6                	mv	a1,s5
     894:	8552                	mv	a0,s4
     896:	00000097          	auipc	ra,0x0
     89a:	dec080e7          	jalr	-532(ra) # 682 <peek>
     89e:	e131                	bnez	a0,8e2 <parseexec+0xfa>
    if ((tok = gettoken(ps, es, &q, &eq)) == 0)
     8a0:	f9040693          	addi	a3,s0,-112
     8a4:	f9840613          	addi	a2,s0,-104
     8a8:	85d6                	mv	a1,s5
     8aa:	8552                	mv	a0,s4
     8ac:	00000097          	auipc	ra,0x0
     8b0:	c9a080e7          	jalr	-870(ra) # 546 <gettoken>
     8b4:	c51d                	beqz	a0,8e2 <parseexec+0xfa>
    if (tok != 'a')
     8b6:	fb951de3          	bne	a0,s9,870 <parseexec+0x88>
    cmd->argv[argc] = q;
     8ba:	f9843783          	ld	a5,-104(s0)
     8be:	00f93023          	sd	a5,0(s2)
    cmd->eargv[argc] = eq;
     8c2:	f9043783          	ld	a5,-112(s0)
     8c6:	04f93823          	sd	a5,80(s2)
    argc++;
     8ca:	2985                	addiw	s3,s3,1
    if (argc >= MAXARGS)
     8cc:	0921                	addi	s2,s2,8
     8ce:	fb7999e3          	bne	s3,s7,880 <parseexec+0x98>
      panic("too many args");
     8d2:	00001517          	auipc	a0,0x1
     8d6:	c5e50513          	addi	a0,a0,-930 # 1530 <malloc+0x1be>
     8da:	00000097          	auipc	ra,0x0
     8de:	8da080e7          	jalr	-1830(ra) # 1b4 <panic>
  cmd->argv[argc] = 0;
     8e2:	098e                	slli	s3,s3,0x3
     8e4:	99e2                	add	s3,s3,s8
     8e6:	0009b423          	sd	zero,8(s3)
  cmd->eargv[argc] = 0;
     8ea:	0409bc23          	sd	zero,88(s3)
  return ret;
     8ee:	b79d                	j	854 <parseexec+0x6c>

00000000000008f0 <parsepipe>:
{
     8f0:	7179                	addi	sp,sp,-48
     8f2:	f406                	sd	ra,40(sp)
     8f4:	f022                	sd	s0,32(sp)
     8f6:	ec26                	sd	s1,24(sp)
     8f8:	e84a                	sd	s2,16(sp)
     8fa:	e44e                	sd	s3,8(sp)
     8fc:	1800                	addi	s0,sp,48
     8fe:	892a                	mv	s2,a0
     900:	89ae                	mv	s3,a1
  cmd = parseexec(ps, es);
     902:	00000097          	auipc	ra,0x0
     906:	ee6080e7          	jalr	-282(ra) # 7e8 <parseexec>
     90a:	84aa                	mv	s1,a0
  if (peek(ps, es, "|"))
     90c:	00001617          	auipc	a2,0x1
     910:	c3c60613          	addi	a2,a2,-964 # 1548 <malloc+0x1d6>
     914:	85ce                	mv	a1,s3
     916:	854a                	mv	a0,s2
     918:	00000097          	auipc	ra,0x0
     91c:	d6a080e7          	jalr	-662(ra) # 682 <peek>
     920:	e909                	bnez	a0,932 <parsepipe+0x42>
}
     922:	8526                	mv	a0,s1
     924:	70a2                	ld	ra,40(sp)
     926:	7402                	ld	s0,32(sp)
     928:	64e2                	ld	s1,24(sp)
     92a:	6942                	ld	s2,16(sp)
     92c:	69a2                	ld	s3,8(sp)
     92e:	6145                	addi	sp,sp,48
     930:	8082                	ret
    gettoken(ps, es, 0, 0);
     932:	4681                	li	a3,0
     934:	4601                	li	a2,0
     936:	85ce                	mv	a1,s3
     938:	854a                	mv	a0,s2
     93a:	00000097          	auipc	ra,0x0
     93e:	c0c080e7          	jalr	-1012(ra) # 546 <gettoken>
    cmd = pipecmd(cmd, parsepipe(ps, es));
     942:	85ce                	mv	a1,s3
     944:	854a                	mv	a0,s2
     946:	00000097          	auipc	ra,0x0
     94a:	faa080e7          	jalr	-86(ra) # 8f0 <parsepipe>
     94e:	85aa                	mv	a1,a0
     950:	8526                	mv	a0,s1
     952:	00000097          	auipc	ra,0x0
     956:	b2c080e7          	jalr	-1236(ra) # 47e <pipecmd>
     95a:	84aa                	mv	s1,a0
  return cmd;
     95c:	b7d9                	j	922 <parsepipe+0x32>

000000000000095e <parseline>:
{
     95e:	7179                	addi	sp,sp,-48
     960:	f406                	sd	ra,40(sp)
     962:	f022                	sd	s0,32(sp)
     964:	ec26                	sd	s1,24(sp)
     966:	e84a                	sd	s2,16(sp)
     968:	e44e                	sd	s3,8(sp)
     96a:	e052                	sd	s4,0(sp)
     96c:	1800                	addi	s0,sp,48
     96e:	892a                	mv	s2,a0
     970:	89ae                	mv	s3,a1
  cmd = parsepipe(ps, es);
     972:	00000097          	auipc	ra,0x0
     976:	f7e080e7          	jalr	-130(ra) # 8f0 <parsepipe>
     97a:	84aa                	mv	s1,a0
  while (peek(ps, es, "&"))
     97c:	00001a17          	auipc	s4,0x1
     980:	bd4a0a13          	addi	s4,s4,-1068 # 1550 <malloc+0x1de>
     984:	a839                	j	9a2 <parseline+0x44>
    gettoken(ps, es, 0, 0);
     986:	4681                	li	a3,0
     988:	4601                	li	a2,0
     98a:	85ce                	mv	a1,s3
     98c:	854a                	mv	a0,s2
     98e:	00000097          	auipc	ra,0x0
     992:	bb8080e7          	jalr	-1096(ra) # 546 <gettoken>
    cmd = backcmd(cmd);
     996:	8526                	mv	a0,s1
     998:	00000097          	auipc	ra,0x0
     99c:	b72080e7          	jalr	-1166(ra) # 50a <backcmd>
     9a0:	84aa                	mv	s1,a0
  while (peek(ps, es, "&"))
     9a2:	8652                	mv	a2,s4
     9a4:	85ce                	mv	a1,s3
     9a6:	854a                	mv	a0,s2
     9a8:	00000097          	auipc	ra,0x0
     9ac:	cda080e7          	jalr	-806(ra) # 682 <peek>
     9b0:	f979                	bnez	a0,986 <parseline+0x28>
  if (peek(ps, es, ";"))
     9b2:	00001617          	auipc	a2,0x1
     9b6:	ba660613          	addi	a2,a2,-1114 # 1558 <malloc+0x1e6>
     9ba:	85ce                	mv	a1,s3
     9bc:	854a                	mv	a0,s2
     9be:	00000097          	auipc	ra,0x0
     9c2:	cc4080e7          	jalr	-828(ra) # 682 <peek>
     9c6:	e911                	bnez	a0,9da <parseline+0x7c>
}
     9c8:	8526                	mv	a0,s1
     9ca:	70a2                	ld	ra,40(sp)
     9cc:	7402                	ld	s0,32(sp)
     9ce:	64e2                	ld	s1,24(sp)
     9d0:	6942                	ld	s2,16(sp)
     9d2:	69a2                	ld	s3,8(sp)
     9d4:	6a02                	ld	s4,0(sp)
     9d6:	6145                	addi	sp,sp,48
     9d8:	8082                	ret
    gettoken(ps, es, 0, 0);
     9da:	4681                	li	a3,0
     9dc:	4601                	li	a2,0
     9de:	85ce                	mv	a1,s3
     9e0:	854a                	mv	a0,s2
     9e2:	00000097          	auipc	ra,0x0
     9e6:	b64080e7          	jalr	-1180(ra) # 546 <gettoken>
    cmd = listcmd(cmd, parseline(ps, es));
     9ea:	85ce                	mv	a1,s3
     9ec:	854a                	mv	a0,s2
     9ee:	00000097          	auipc	ra,0x0
     9f2:	f70080e7          	jalr	-144(ra) # 95e <parseline>
     9f6:	85aa                	mv	a1,a0
     9f8:	8526                	mv	a0,s1
     9fa:	00000097          	auipc	ra,0x0
     9fe:	aca080e7          	jalr	-1334(ra) # 4c4 <listcmd>
     a02:	84aa                	mv	s1,a0
  return cmd;
     a04:	b7d1                	j	9c8 <parseline+0x6a>

0000000000000a06 <parseblock>:
{
     a06:	7179                	addi	sp,sp,-48
     a08:	f406                	sd	ra,40(sp)
     a0a:	f022                	sd	s0,32(sp)
     a0c:	ec26                	sd	s1,24(sp)
     a0e:	e84a                	sd	s2,16(sp)
     a10:	e44e                	sd	s3,8(sp)
     a12:	1800                	addi	s0,sp,48
     a14:	84aa                	mv	s1,a0
     a16:	892e                	mv	s2,a1
  if (!peek(ps, es, "("))
     a18:	00001617          	auipc	a2,0x1
     a1c:	b0860613          	addi	a2,a2,-1272 # 1520 <malloc+0x1ae>
     a20:	00000097          	auipc	ra,0x0
     a24:	c62080e7          	jalr	-926(ra) # 682 <peek>
     a28:	c12d                	beqz	a0,a8a <parseblock+0x84>
  gettoken(ps, es, 0, 0);
     a2a:	4681                	li	a3,0
     a2c:	4601                	li	a2,0
     a2e:	85ca                	mv	a1,s2
     a30:	8526                	mv	a0,s1
     a32:	00000097          	auipc	ra,0x0
     a36:	b14080e7          	jalr	-1260(ra) # 546 <gettoken>
  cmd = parseline(ps, es);
     a3a:	85ca                	mv	a1,s2
     a3c:	8526                	mv	a0,s1
     a3e:	00000097          	auipc	ra,0x0
     a42:	f20080e7          	jalr	-224(ra) # 95e <parseline>
     a46:	89aa                	mv	s3,a0
  if (!peek(ps, es, ")"))
     a48:	00001617          	auipc	a2,0x1
     a4c:	b2860613          	addi	a2,a2,-1240 # 1570 <malloc+0x1fe>
     a50:	85ca                	mv	a1,s2
     a52:	8526                	mv	a0,s1
     a54:	00000097          	auipc	ra,0x0
     a58:	c2e080e7          	jalr	-978(ra) # 682 <peek>
     a5c:	cd1d                	beqz	a0,a9a <parseblock+0x94>
  gettoken(ps, es, 0, 0);
     a5e:	4681                	li	a3,0
     a60:	4601                	li	a2,0
     a62:	85ca                	mv	a1,s2
     a64:	8526                	mv	a0,s1
     a66:	00000097          	auipc	ra,0x0
     a6a:	ae0080e7          	jalr	-1312(ra) # 546 <gettoken>
  cmd = parseredirs(cmd, ps, es);
     a6e:	864a                	mv	a2,s2
     a70:	85a6                	mv	a1,s1
     a72:	854e                	mv	a0,s3
     a74:	00000097          	auipc	ra,0x0
     a78:	c78080e7          	jalr	-904(ra) # 6ec <parseredirs>
}
     a7c:	70a2                	ld	ra,40(sp)
     a7e:	7402                	ld	s0,32(sp)
     a80:	64e2                	ld	s1,24(sp)
     a82:	6942                	ld	s2,16(sp)
     a84:	69a2                	ld	s3,8(sp)
     a86:	6145                	addi	sp,sp,48
     a88:	8082                	ret
    panic("parseblock");
     a8a:	00001517          	auipc	a0,0x1
     a8e:	ad650513          	addi	a0,a0,-1322 # 1560 <malloc+0x1ee>
     a92:	fffff097          	auipc	ra,0xfffff
     a96:	722080e7          	jalr	1826(ra) # 1b4 <panic>
    panic("syntax - missing )");
     a9a:	00001517          	auipc	a0,0x1
     a9e:	ade50513          	addi	a0,a0,-1314 # 1578 <malloc+0x206>
     aa2:	fffff097          	auipc	ra,0xfffff
     aa6:	712080e7          	jalr	1810(ra) # 1b4 <panic>

0000000000000aaa <nulterminate>:

// NUL-terminate all the counted strings.
struct cmd *
nulterminate(struct cmd *cmd)
{
     aaa:	1101                	addi	sp,sp,-32
     aac:	ec06                	sd	ra,24(sp)
     aae:	e822                	sd	s0,16(sp)
     ab0:	e426                	sd	s1,8(sp)
     ab2:	1000                	addi	s0,sp,32
     ab4:	84aa                	mv	s1,a0
  struct execcmd *ecmd;
  struct listcmd *lcmd;
  struct pipecmd *pcmd;
  struct redircmd *rcmd;

  if (cmd == 0)
     ab6:	c521                	beqz	a0,afe <nulterminate+0x54>
    return 0;

  switch (cmd->type)
     ab8:	4118                	lw	a4,0(a0)
     aba:	4795                	li	a5,5
     abc:	04e7e163          	bltu	a5,a4,afe <nulterminate+0x54>
     ac0:	00056783          	lwu	a5,0(a0)
     ac4:	078a                	slli	a5,a5,0x2
     ac6:	00001717          	auipc	a4,0x1
     aca:	b0a70713          	addi	a4,a4,-1270 # 15d0 <malloc+0x25e>
     ace:	97ba                	add	a5,a5,a4
     ad0:	439c                	lw	a5,0(a5)
     ad2:	97ba                	add	a5,a5,a4
     ad4:	8782                	jr	a5
  {
  case EXEC:
    ecmd = (struct execcmd *)cmd;
    for (i = 0; ecmd->argv[i]; i++)
     ad6:	651c                	ld	a5,8(a0)
     ad8:	c39d                	beqz	a5,afe <nulterminate+0x54>
     ada:	01050793          	addi	a5,a0,16
      *ecmd->eargv[i] = 0;
     ade:	67b8                	ld	a4,72(a5)
     ae0:	00070023          	sb	zero,0(a4)
    for (i = 0; ecmd->argv[i]; i++)
     ae4:	07a1                	addi	a5,a5,8
     ae6:	ff87b703          	ld	a4,-8(a5)
     aea:	fb75                	bnez	a4,ade <nulterminate+0x34>
     aec:	a809                	j	afe <nulterminate+0x54>
    break;

  case REDIR:
    rcmd = (struct redircmd *)cmd;
    nulterminate(rcmd->cmd);
     aee:	6508                	ld	a0,8(a0)
     af0:	00000097          	auipc	ra,0x0
     af4:	fba080e7          	jalr	-70(ra) # aaa <nulterminate>
    *rcmd->efile = 0;
     af8:	6c9c                	ld	a5,24(s1)
     afa:	00078023          	sb	zero,0(a5)
    bcmd = (struct backcmd *)cmd;
    nulterminate(bcmd->cmd);
    break;
  }
  return cmd;
}
     afe:	8526                	mv	a0,s1
     b00:	60e2                	ld	ra,24(sp)
     b02:	6442                	ld	s0,16(sp)
     b04:	64a2                	ld	s1,8(sp)
     b06:	6105                	addi	sp,sp,32
     b08:	8082                	ret
    nulterminate(pcmd->left);
     b0a:	6508                	ld	a0,8(a0)
     b0c:	00000097          	auipc	ra,0x0
     b10:	f9e080e7          	jalr	-98(ra) # aaa <nulterminate>
    nulterminate(pcmd->right);
     b14:	6888                	ld	a0,16(s1)
     b16:	00000097          	auipc	ra,0x0
     b1a:	f94080e7          	jalr	-108(ra) # aaa <nulterminate>
    break;
     b1e:	b7c5                	j	afe <nulterminate+0x54>
    nulterminate(lcmd->left);
     b20:	6508                	ld	a0,8(a0)
     b22:	00000097          	auipc	ra,0x0
     b26:	f88080e7          	jalr	-120(ra) # aaa <nulterminate>
    nulterminate(lcmd->right);
     b2a:	6888                	ld	a0,16(s1)
     b2c:	00000097          	auipc	ra,0x0
     b30:	f7e080e7          	jalr	-130(ra) # aaa <nulterminate>
    break;
     b34:	b7e9                	j	afe <nulterminate+0x54>
    nulterminate(bcmd->cmd);
     b36:	6508                	ld	a0,8(a0)
     b38:	00000097          	auipc	ra,0x0
     b3c:	f72080e7          	jalr	-142(ra) # aaa <nulterminate>
    break;
     b40:	bf7d                	j	afe <nulterminate+0x54>

0000000000000b42 <parsecmd>:
{
     b42:	7179                	addi	sp,sp,-48
     b44:	f406                	sd	ra,40(sp)
     b46:	f022                	sd	s0,32(sp)
     b48:	ec26                	sd	s1,24(sp)
     b4a:	e84a                	sd	s2,16(sp)
     b4c:	1800                	addi	s0,sp,48
     b4e:	fca43c23          	sd	a0,-40(s0)
  es = s + strlen(s);
     b52:	84aa                	mv	s1,a0
     b54:	00000097          	auipc	ra,0x0
     b58:	1b2080e7          	jalr	434(ra) # d06 <strlen>
     b5c:	1502                	slli	a0,a0,0x20
     b5e:	9101                	srli	a0,a0,0x20
     b60:	94aa                	add	s1,s1,a0
  cmd = parseline(&s, es);
     b62:	85a6                	mv	a1,s1
     b64:	fd840513          	addi	a0,s0,-40
     b68:	00000097          	auipc	ra,0x0
     b6c:	df6080e7          	jalr	-522(ra) # 95e <parseline>
     b70:	892a                	mv	s2,a0
  peek(&s, es, "");
     b72:	00001617          	auipc	a2,0x1
     b76:	90660613          	addi	a2,a2,-1786 # 1478 <malloc+0x106>
     b7a:	85a6                	mv	a1,s1
     b7c:	fd840513          	addi	a0,s0,-40
     b80:	00000097          	auipc	ra,0x0
     b84:	b02080e7          	jalr	-1278(ra) # 682 <peek>
  if (s != es)
     b88:	fd843603          	ld	a2,-40(s0)
     b8c:	00961e63          	bne	a2,s1,ba8 <parsecmd+0x66>
  nulterminate(cmd);
     b90:	854a                	mv	a0,s2
     b92:	00000097          	auipc	ra,0x0
     b96:	f18080e7          	jalr	-232(ra) # aaa <nulterminate>
}
     b9a:	854a                	mv	a0,s2
     b9c:	70a2                	ld	ra,40(sp)
     b9e:	7402                	ld	s0,32(sp)
     ba0:	64e2                	ld	s1,24(sp)
     ba2:	6942                	ld	s2,16(sp)
     ba4:	6145                	addi	sp,sp,48
     ba6:	8082                	ret
    fprintf(2, "leftovers: %s\n", s);
     ba8:	00001597          	auipc	a1,0x1
     bac:	9e858593          	addi	a1,a1,-1560 # 1590 <malloc+0x21e>
     bb0:	4509                	li	a0,2
     bb2:	00000097          	auipc	ra,0x0
     bb6:	6d4080e7          	jalr	1748(ra) # 1286 <fprintf>
    panic("syntax");
     bba:	00001517          	auipc	a0,0x1
     bbe:	96e50513          	addi	a0,a0,-1682 # 1528 <malloc+0x1b6>
     bc2:	fffff097          	auipc	ra,0xfffff
     bc6:	5f2080e7          	jalr	1522(ra) # 1b4 <panic>

0000000000000bca <main>:
{
     bca:	7139                	addi	sp,sp,-64
     bcc:	fc06                	sd	ra,56(sp)
     bce:	f822                	sd	s0,48(sp)
     bd0:	f426                	sd	s1,40(sp)
     bd2:	f04a                	sd	s2,32(sp)
     bd4:	ec4e                	sd	s3,24(sp)
     bd6:	e852                	sd	s4,16(sp)
     bd8:	e456                	sd	s5,8(sp)
     bda:	0080                	addi	s0,sp,64
  while ((fd = open("console", O_RDWR)) >= 0)
     bdc:	00001497          	auipc	s1,0x1
     be0:	9c448493          	addi	s1,s1,-1596 # 15a0 <malloc+0x22e>
     be4:	4589                	li	a1,2
     be6:	8526                	mv	a0,s1
     be8:	00000097          	auipc	ra,0x0
     bec:	384080e7          	jalr	900(ra) # f6c <open>
     bf0:	00054963          	bltz	a0,c02 <main+0x38>
    if (fd >= 3)
     bf4:	4789                	li	a5,2
     bf6:	fea7d7e3          	bge	a5,a0,be4 <main+0x1a>
      close(fd);
     bfa:	00000097          	auipc	ra,0x0
     bfe:	35a080e7          	jalr	858(ra) # f54 <close>
  while (getcmd(buf, sizeof(buf)) >= 0)
     c02:	00001497          	auipc	s1,0x1
     c06:	a1e48493          	addi	s1,s1,-1506 # 1620 <buf.0>
    if (buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' ')
     c0a:	06300913          	li	s2,99
     c0e:	02000993          	li	s3,32
      if (chdir(buf + 3) < 0)
     c12:	00001a17          	auipc	s4,0x1
     c16:	a11a0a13          	addi	s4,s4,-1519 # 1623 <buf.0+0x3>
        fprintf(2, "cannot cd %s\n", buf + 3);
     c1a:	00001a97          	auipc	s5,0x1
     c1e:	98ea8a93          	addi	s5,s5,-1650 # 15a8 <malloc+0x236>
     c22:	a819                	j	c38 <main+0x6e>
    if (fork1() == 0)
     c24:	fffff097          	auipc	ra,0xfffff
     c28:	5b6080e7          	jalr	1462(ra) # 1da <fork1>
     c2c:	c925                	beqz	a0,c9c <main+0xd2>
    wait(0);
     c2e:	4501                	li	a0,0
     c30:	00000097          	auipc	ra,0x0
     c34:	304080e7          	jalr	772(ra) # f34 <wait>
  while (getcmd(buf, sizeof(buf)) >= 0)
     c38:	06400593          	li	a1,100
     c3c:	8526                	mv	a0,s1
     c3e:	fffff097          	auipc	ra,0xfffff
     c42:	522080e7          	jalr	1314(ra) # 160 <getcmd>
     c46:	06054763          	bltz	a0,cb4 <main+0xea>
    if (buf[0] == 'c' && buf[1] == 'd' && buf[2] == ' ')
     c4a:	0004c783          	lbu	a5,0(s1)
     c4e:	fd279be3          	bne	a5,s2,c24 <main+0x5a>
     c52:	0014c703          	lbu	a4,1(s1)
     c56:	06400793          	li	a5,100
     c5a:	fcf715e3          	bne	a4,a5,c24 <main+0x5a>
     c5e:	0024c783          	lbu	a5,2(s1)
     c62:	fd3791e3          	bne	a5,s3,c24 <main+0x5a>
      buf[strlen(buf) - 1] = 0; // chop \n
     c66:	8526                	mv	a0,s1
     c68:	00000097          	auipc	ra,0x0
     c6c:	09e080e7          	jalr	158(ra) # d06 <strlen>
     c70:	fff5079b          	addiw	a5,a0,-1
     c74:	1782                	slli	a5,a5,0x20
     c76:	9381                	srli	a5,a5,0x20
     c78:	97a6                	add	a5,a5,s1
     c7a:	00078023          	sb	zero,0(a5)
      if (chdir(buf + 3) < 0)
     c7e:	8552                	mv	a0,s4
     c80:	00000097          	auipc	ra,0x0
     c84:	31c080e7          	jalr	796(ra) # f9c <chdir>
     c88:	fa0558e3          	bgez	a0,c38 <main+0x6e>
        fprintf(2, "cannot cd %s\n", buf + 3);
     c8c:	8652                	mv	a2,s4
     c8e:	85d6                	mv	a1,s5
     c90:	4509                	li	a0,2
     c92:	00000097          	auipc	ra,0x0
     c96:	5f4080e7          	jalr	1524(ra) # 1286 <fprintf>
     c9a:	bf79                	j	c38 <main+0x6e>
      runcmd(parsecmd(buf));
     c9c:	00001517          	auipc	a0,0x1
     ca0:	98450513          	addi	a0,a0,-1660 # 1620 <buf.0>
     ca4:	00000097          	auipc	ra,0x0
     ca8:	e9e080e7          	jalr	-354(ra) # b42 <parsecmd>
     cac:	fffff097          	auipc	ra,0xfffff
     cb0:	55c080e7          	jalr	1372(ra) # 208 <runcmd>
  exit(0);
     cb4:	4501                	li	a0,0
     cb6:	00000097          	auipc	ra,0x0
     cba:	276080e7          	jalr	630(ra) # f2c <exit>

0000000000000cbe <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
     cbe:	1141                	addi	sp,sp,-16
     cc0:	e422                	sd	s0,8(sp)
     cc2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
     cc4:	87aa                	mv	a5,a0
     cc6:	0585                	addi	a1,a1,1
     cc8:	0785                	addi	a5,a5,1
     cca:	fff5c703          	lbu	a4,-1(a1)
     cce:	fee78fa3          	sb	a4,-1(a5)
     cd2:	fb75                	bnez	a4,cc6 <strcpy+0x8>
    ;
  return os;
}
     cd4:	6422                	ld	s0,8(sp)
     cd6:	0141                	addi	sp,sp,16
     cd8:	8082                	ret

0000000000000cda <strcmp>:

int
strcmp(const char *p, const char *q)
{
     cda:	1141                	addi	sp,sp,-16
     cdc:	e422                	sd	s0,8(sp)
     cde:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
     ce0:	00054783          	lbu	a5,0(a0)
     ce4:	cb91                	beqz	a5,cf8 <strcmp+0x1e>
     ce6:	0005c703          	lbu	a4,0(a1)
     cea:	00f71763          	bne	a4,a5,cf8 <strcmp+0x1e>
    p++, q++;
     cee:	0505                	addi	a0,a0,1
     cf0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
     cf2:	00054783          	lbu	a5,0(a0)
     cf6:	fbe5                	bnez	a5,ce6 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
     cf8:	0005c503          	lbu	a0,0(a1)
}
     cfc:	40a7853b          	subw	a0,a5,a0
     d00:	6422                	ld	s0,8(sp)
     d02:	0141                	addi	sp,sp,16
     d04:	8082                	ret

0000000000000d06 <strlen>:

uint
strlen(const char *s)
{
     d06:	1141                	addi	sp,sp,-16
     d08:	e422                	sd	s0,8(sp)
     d0a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
     d0c:	00054783          	lbu	a5,0(a0)
     d10:	cf91                	beqz	a5,d2c <strlen+0x26>
     d12:	0505                	addi	a0,a0,1
     d14:	87aa                	mv	a5,a0
     d16:	4685                	li	a3,1
     d18:	9e89                	subw	a3,a3,a0
     d1a:	00f6853b          	addw	a0,a3,a5
     d1e:	0785                	addi	a5,a5,1
     d20:	fff7c703          	lbu	a4,-1(a5)
     d24:	fb7d                	bnez	a4,d1a <strlen+0x14>
    ;
  return n;
}
     d26:	6422                	ld	s0,8(sp)
     d28:	0141                	addi	sp,sp,16
     d2a:	8082                	ret
  for(n = 0; s[n]; n++)
     d2c:	4501                	li	a0,0
     d2e:	bfe5                	j	d26 <strlen+0x20>

0000000000000d30 <memset>:

void*
memset(void *dst, int c, uint n)
{
     d30:	1141                	addi	sp,sp,-16
     d32:	e422                	sd	s0,8(sp)
     d34:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
     d36:	ca19                	beqz	a2,d4c <memset+0x1c>
     d38:	87aa                	mv	a5,a0
     d3a:	1602                	slli	a2,a2,0x20
     d3c:	9201                	srli	a2,a2,0x20
     d3e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
     d42:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
     d46:	0785                	addi	a5,a5,1
     d48:	fee79de3          	bne	a5,a4,d42 <memset+0x12>
  }
  return dst;
}
     d4c:	6422                	ld	s0,8(sp)
     d4e:	0141                	addi	sp,sp,16
     d50:	8082                	ret

0000000000000d52 <strchr>:

char*
strchr(const char *s, char c)
{
     d52:	1141                	addi	sp,sp,-16
     d54:	e422                	sd	s0,8(sp)
     d56:	0800                	addi	s0,sp,16
  for(; *s; s++)
     d58:	00054783          	lbu	a5,0(a0)
     d5c:	cb99                	beqz	a5,d72 <strchr+0x20>
    if(*s == c)
     d5e:	00f58763          	beq	a1,a5,d6c <strchr+0x1a>
  for(; *s; s++)
     d62:	0505                	addi	a0,a0,1
     d64:	00054783          	lbu	a5,0(a0)
     d68:	fbfd                	bnez	a5,d5e <strchr+0xc>
      return (char*)s;
  return 0;
     d6a:	4501                	li	a0,0
}
     d6c:	6422                	ld	s0,8(sp)
     d6e:	0141                	addi	sp,sp,16
     d70:	8082                	ret
  return 0;
     d72:	4501                	li	a0,0
     d74:	bfe5                	j	d6c <strchr+0x1a>

0000000000000d76 <gets>:

char*
gets(char *buf, int max)
{
     d76:	711d                	addi	sp,sp,-96
     d78:	ec86                	sd	ra,88(sp)
     d7a:	e8a2                	sd	s0,80(sp)
     d7c:	e4a6                	sd	s1,72(sp)
     d7e:	e0ca                	sd	s2,64(sp)
     d80:	fc4e                	sd	s3,56(sp)
     d82:	f852                	sd	s4,48(sp)
     d84:	f456                	sd	s5,40(sp)
     d86:	f05a                	sd	s6,32(sp)
     d88:	ec5e                	sd	s7,24(sp)
     d8a:	1080                	addi	s0,sp,96
     d8c:	8baa                	mv	s7,a0
     d8e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
     d90:	892a                	mv	s2,a0
     d92:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
     d94:	4aa9                	li	s5,10
     d96:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
     d98:	89a6                	mv	s3,s1
     d9a:	2485                	addiw	s1,s1,1
     d9c:	0344d863          	bge	s1,s4,dcc <gets+0x56>
    cc = read(0, &c, 1);
     da0:	4605                	li	a2,1
     da2:	faf40593          	addi	a1,s0,-81
     da6:	4501                	li	a0,0
     da8:	00000097          	auipc	ra,0x0
     dac:	19c080e7          	jalr	412(ra) # f44 <read>
    if(cc < 1)
     db0:	00a05e63          	blez	a0,dcc <gets+0x56>
    buf[i++] = c;
     db4:	faf44783          	lbu	a5,-81(s0)
     db8:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
     dbc:	01578763          	beq	a5,s5,dca <gets+0x54>
     dc0:	0905                	addi	s2,s2,1
     dc2:	fd679be3          	bne	a5,s6,d98 <gets+0x22>
  for(i=0; i+1 < max; ){
     dc6:	89a6                	mv	s3,s1
     dc8:	a011                	j	dcc <gets+0x56>
     dca:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
     dcc:	99de                	add	s3,s3,s7
     dce:	00098023          	sb	zero,0(s3)
  return buf;
}
     dd2:	855e                	mv	a0,s7
     dd4:	60e6                	ld	ra,88(sp)
     dd6:	6446                	ld	s0,80(sp)
     dd8:	64a6                	ld	s1,72(sp)
     dda:	6906                	ld	s2,64(sp)
     ddc:	79e2                	ld	s3,56(sp)
     dde:	7a42                	ld	s4,48(sp)
     de0:	7aa2                	ld	s5,40(sp)
     de2:	7b02                	ld	s6,32(sp)
     de4:	6be2                	ld	s7,24(sp)
     de6:	6125                	addi	sp,sp,96
     de8:	8082                	ret

0000000000000dea <stat>:

int
stat(const char *n, struct stat *st)
{
     dea:	1101                	addi	sp,sp,-32
     dec:	ec06                	sd	ra,24(sp)
     dee:	e822                	sd	s0,16(sp)
     df0:	e426                	sd	s1,8(sp)
     df2:	e04a                	sd	s2,0(sp)
     df4:	1000                	addi	s0,sp,32
     df6:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
     df8:	4581                	li	a1,0
     dfa:	00000097          	auipc	ra,0x0
     dfe:	172080e7          	jalr	370(ra) # f6c <open>
  if(fd < 0)
     e02:	02054563          	bltz	a0,e2c <stat+0x42>
     e06:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
     e08:	85ca                	mv	a1,s2
     e0a:	00000097          	auipc	ra,0x0
     e0e:	17a080e7          	jalr	378(ra) # f84 <fstat>
     e12:	892a                	mv	s2,a0
  close(fd);
     e14:	8526                	mv	a0,s1
     e16:	00000097          	auipc	ra,0x0
     e1a:	13e080e7          	jalr	318(ra) # f54 <close>
  return r;
}
     e1e:	854a                	mv	a0,s2
     e20:	60e2                	ld	ra,24(sp)
     e22:	6442                	ld	s0,16(sp)
     e24:	64a2                	ld	s1,8(sp)
     e26:	6902                	ld	s2,0(sp)
     e28:	6105                	addi	sp,sp,32
     e2a:	8082                	ret
    return -1;
     e2c:	597d                	li	s2,-1
     e2e:	bfc5                	j	e1e <stat+0x34>

0000000000000e30 <atoi>:

int
atoi(const char *s)
{
     e30:	1141                	addi	sp,sp,-16
     e32:	e422                	sd	s0,8(sp)
     e34:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
     e36:	00054603          	lbu	a2,0(a0)
     e3a:	fd06079b          	addiw	a5,a2,-48
     e3e:	0ff7f793          	andi	a5,a5,255
     e42:	4725                	li	a4,9
     e44:	02f76963          	bltu	a4,a5,e76 <atoi+0x46>
     e48:	86aa                	mv	a3,a0
  n = 0;
     e4a:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
     e4c:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
     e4e:	0685                	addi	a3,a3,1
     e50:	0025179b          	slliw	a5,a0,0x2
     e54:	9fa9                	addw	a5,a5,a0
     e56:	0017979b          	slliw	a5,a5,0x1
     e5a:	9fb1                	addw	a5,a5,a2
     e5c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
     e60:	0006c603          	lbu	a2,0(a3)
     e64:	fd06071b          	addiw	a4,a2,-48
     e68:	0ff77713          	andi	a4,a4,255
     e6c:	fee5f1e3          	bgeu	a1,a4,e4e <atoi+0x1e>
  return n;
}
     e70:	6422                	ld	s0,8(sp)
     e72:	0141                	addi	sp,sp,16
     e74:	8082                	ret
  n = 0;
     e76:	4501                	li	a0,0
     e78:	bfe5                	j	e70 <atoi+0x40>

0000000000000e7a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
     e7a:	1141                	addi	sp,sp,-16
     e7c:	e422                	sd	s0,8(sp)
     e7e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
     e80:	02b57463          	bgeu	a0,a1,ea8 <memmove+0x2e>
    while(n-- > 0)
     e84:	00c05f63          	blez	a2,ea2 <memmove+0x28>
     e88:	1602                	slli	a2,a2,0x20
     e8a:	9201                	srli	a2,a2,0x20
     e8c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
     e90:	872a                	mv	a4,a0
      *dst++ = *src++;
     e92:	0585                	addi	a1,a1,1
     e94:	0705                	addi	a4,a4,1
     e96:	fff5c683          	lbu	a3,-1(a1)
     e9a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
     e9e:	fee79ae3          	bne	a5,a4,e92 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
     ea2:	6422                	ld	s0,8(sp)
     ea4:	0141                	addi	sp,sp,16
     ea6:	8082                	ret
    dst += n;
     ea8:	00c50733          	add	a4,a0,a2
    src += n;
     eac:	95b2                	add	a1,a1,a2
    while(n-- > 0)
     eae:	fec05ae3          	blez	a2,ea2 <memmove+0x28>
     eb2:	fff6079b          	addiw	a5,a2,-1
     eb6:	1782                	slli	a5,a5,0x20
     eb8:	9381                	srli	a5,a5,0x20
     eba:	fff7c793          	not	a5,a5
     ebe:	97ba                	add	a5,a5,a4
      *--dst = *--src;
     ec0:	15fd                	addi	a1,a1,-1
     ec2:	177d                	addi	a4,a4,-1
     ec4:	0005c683          	lbu	a3,0(a1)
     ec8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
     ecc:	fee79ae3          	bne	a5,a4,ec0 <memmove+0x46>
     ed0:	bfc9                	j	ea2 <memmove+0x28>

0000000000000ed2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
     ed2:	1141                	addi	sp,sp,-16
     ed4:	e422                	sd	s0,8(sp)
     ed6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
     ed8:	ca05                	beqz	a2,f08 <memcmp+0x36>
     eda:	fff6069b          	addiw	a3,a2,-1
     ede:	1682                	slli	a3,a3,0x20
     ee0:	9281                	srli	a3,a3,0x20
     ee2:	0685                	addi	a3,a3,1
     ee4:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
     ee6:	00054783          	lbu	a5,0(a0)
     eea:	0005c703          	lbu	a4,0(a1)
     eee:	00e79863          	bne	a5,a4,efe <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
     ef2:	0505                	addi	a0,a0,1
    p2++;
     ef4:	0585                	addi	a1,a1,1
  while (n-- > 0) {
     ef6:	fed518e3          	bne	a0,a3,ee6 <memcmp+0x14>
  }
  return 0;
     efa:	4501                	li	a0,0
     efc:	a019                	j	f02 <memcmp+0x30>
      return *p1 - *p2;
     efe:	40e7853b          	subw	a0,a5,a4
}
     f02:	6422                	ld	s0,8(sp)
     f04:	0141                	addi	sp,sp,16
     f06:	8082                	ret
  return 0;
     f08:	4501                	li	a0,0
     f0a:	bfe5                	j	f02 <memcmp+0x30>

0000000000000f0c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
     f0c:	1141                	addi	sp,sp,-16
     f0e:	e406                	sd	ra,8(sp)
     f10:	e022                	sd	s0,0(sp)
     f12:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
     f14:	00000097          	auipc	ra,0x0
     f18:	f66080e7          	jalr	-154(ra) # e7a <memmove>
}
     f1c:	60a2                	ld	ra,8(sp)
     f1e:	6402                	ld	s0,0(sp)
     f20:	0141                	addi	sp,sp,16
     f22:	8082                	ret

0000000000000f24 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
     f24:	4885                	li	a7,1
 ecall
     f26:	00000073          	ecall
 ret
     f2a:	8082                	ret

0000000000000f2c <exit>:
.global exit
exit:
 li a7, SYS_exit
     f2c:	4889                	li	a7,2
 ecall
     f2e:	00000073          	ecall
 ret
     f32:	8082                	ret

0000000000000f34 <wait>:
.global wait
wait:
 li a7, SYS_wait
     f34:	488d                	li	a7,3
 ecall
     f36:	00000073          	ecall
 ret
     f3a:	8082                	ret

0000000000000f3c <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
     f3c:	4891                	li	a7,4
 ecall
     f3e:	00000073          	ecall
 ret
     f42:	8082                	ret

0000000000000f44 <read>:
.global read
read:
 li a7, SYS_read
     f44:	4895                	li	a7,5
 ecall
     f46:	00000073          	ecall
 ret
     f4a:	8082                	ret

0000000000000f4c <write>:
.global write
write:
 li a7, SYS_write
     f4c:	48c1                	li	a7,16
 ecall
     f4e:	00000073          	ecall
 ret
     f52:	8082                	ret

0000000000000f54 <close>:
.global close
close:
 li a7, SYS_close
     f54:	48d5                	li	a7,21
 ecall
     f56:	00000073          	ecall
 ret
     f5a:	8082                	ret

0000000000000f5c <kill>:
.global kill
kill:
 li a7, SYS_kill
     f5c:	4899                	li	a7,6
 ecall
     f5e:	00000073          	ecall
 ret
     f62:	8082                	ret

0000000000000f64 <exec>:
.global exec
exec:
 li a7, SYS_exec
     f64:	489d                	li	a7,7
 ecall
     f66:	00000073          	ecall
 ret
     f6a:	8082                	ret

0000000000000f6c <open>:
.global open
open:
 li a7, SYS_open
     f6c:	48bd                	li	a7,15
 ecall
     f6e:	00000073          	ecall
 ret
     f72:	8082                	ret

0000000000000f74 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
     f74:	48c5                	li	a7,17
 ecall
     f76:	00000073          	ecall
 ret
     f7a:	8082                	ret

0000000000000f7c <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
     f7c:	48c9                	li	a7,18
 ecall
     f7e:	00000073          	ecall
 ret
     f82:	8082                	ret

0000000000000f84 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
     f84:	48a1                	li	a7,8
 ecall
     f86:	00000073          	ecall
 ret
     f8a:	8082                	ret

0000000000000f8c <link>:
.global link
link:
 li a7, SYS_link
     f8c:	48cd                	li	a7,19
 ecall
     f8e:	00000073          	ecall
 ret
     f92:	8082                	ret

0000000000000f94 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
     f94:	48d1                	li	a7,20
 ecall
     f96:	00000073          	ecall
 ret
     f9a:	8082                	ret

0000000000000f9c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
     f9c:	48a5                	li	a7,9
 ecall
     f9e:	00000073          	ecall
 ret
     fa2:	8082                	ret

0000000000000fa4 <dup>:
.global dup
dup:
 li a7, SYS_dup
     fa4:	48a9                	li	a7,10
 ecall
     fa6:	00000073          	ecall
 ret
     faa:	8082                	ret

0000000000000fac <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
     fac:	48ad                	li	a7,11
 ecall
     fae:	00000073          	ecall
 ret
     fb2:	8082                	ret

0000000000000fb4 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
     fb4:	48b1                	li	a7,12
 ecall
     fb6:	00000073          	ecall
 ret
     fba:	8082                	ret

0000000000000fbc <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
     fbc:	48b5                	li	a7,13
 ecall
     fbe:	00000073          	ecall
 ret
     fc2:	8082                	ret

0000000000000fc4 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
     fc4:	48b9                	li	a7,14
 ecall
     fc6:	00000073          	ecall
 ret
     fca:	8082                	ret

0000000000000fcc <trace>:
.global trace
trace:
 li a7, SYS_trace
     fcc:	48d9                	li	a7,22
 ecall
     fce:	00000073          	ecall
 ret
     fd2:	8082                	ret

0000000000000fd4 <wait_stat>:
.global wait_stat
wait_stat:
 li a7, SYS_wait_stat
     fd4:	48dd                	li	a7,23
 ecall
     fd6:	00000073          	ecall
 ret
     fda:	8082                	ret

0000000000000fdc <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
     fdc:	1101                	addi	sp,sp,-32
     fde:	ec06                	sd	ra,24(sp)
     fe0:	e822                	sd	s0,16(sp)
     fe2:	1000                	addi	s0,sp,32
     fe4:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
     fe8:	4605                	li	a2,1
     fea:	fef40593          	addi	a1,s0,-17
     fee:	00000097          	auipc	ra,0x0
     ff2:	f5e080e7          	jalr	-162(ra) # f4c <write>
}
     ff6:	60e2                	ld	ra,24(sp)
     ff8:	6442                	ld	s0,16(sp)
     ffa:	6105                	addi	sp,sp,32
     ffc:	8082                	ret

0000000000000ffe <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
     ffe:	7139                	addi	sp,sp,-64
    1000:	fc06                	sd	ra,56(sp)
    1002:	f822                	sd	s0,48(sp)
    1004:	f426                	sd	s1,40(sp)
    1006:	f04a                	sd	s2,32(sp)
    1008:	ec4e                	sd	s3,24(sp)
    100a:	0080                	addi	s0,sp,64
    100c:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
    100e:	c299                	beqz	a3,1014 <printint+0x16>
    1010:	0805c863          	bltz	a1,10a0 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
    1014:	2581                	sext.w	a1,a1
  neg = 0;
    1016:	4881                	li	a7,0
    1018:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
    101c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
    101e:	2601                	sext.w	a2,a2
    1020:	00000517          	auipc	a0,0x0
    1024:	5d050513          	addi	a0,a0,1488 # 15f0 <digits>
    1028:	883a                	mv	a6,a4
    102a:	2705                	addiw	a4,a4,1
    102c:	02c5f7bb          	remuw	a5,a1,a2
    1030:	1782                	slli	a5,a5,0x20
    1032:	9381                	srli	a5,a5,0x20
    1034:	97aa                	add	a5,a5,a0
    1036:	0007c783          	lbu	a5,0(a5)
    103a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
    103e:	0005879b          	sext.w	a5,a1
    1042:	02c5d5bb          	divuw	a1,a1,a2
    1046:	0685                	addi	a3,a3,1
    1048:	fec7f0e3          	bgeu	a5,a2,1028 <printint+0x2a>
  if(neg)
    104c:	00088b63          	beqz	a7,1062 <printint+0x64>
    buf[i++] = '-';
    1050:	fd040793          	addi	a5,s0,-48
    1054:	973e                	add	a4,a4,a5
    1056:	02d00793          	li	a5,45
    105a:	fef70823          	sb	a5,-16(a4)
    105e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    1062:	02e05863          	blez	a4,1092 <printint+0x94>
    1066:	fc040793          	addi	a5,s0,-64
    106a:	00e78933          	add	s2,a5,a4
    106e:	fff78993          	addi	s3,a5,-1
    1072:	99ba                	add	s3,s3,a4
    1074:	377d                	addiw	a4,a4,-1
    1076:	1702                	slli	a4,a4,0x20
    1078:	9301                	srli	a4,a4,0x20
    107a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
    107e:	fff94583          	lbu	a1,-1(s2)
    1082:	8526                	mv	a0,s1
    1084:	00000097          	auipc	ra,0x0
    1088:	f58080e7          	jalr	-168(ra) # fdc <putc>
  while(--i >= 0)
    108c:	197d                	addi	s2,s2,-1
    108e:	ff3918e3          	bne	s2,s3,107e <printint+0x80>
}
    1092:	70e2                	ld	ra,56(sp)
    1094:	7442                	ld	s0,48(sp)
    1096:	74a2                	ld	s1,40(sp)
    1098:	7902                	ld	s2,32(sp)
    109a:	69e2                	ld	s3,24(sp)
    109c:	6121                	addi	sp,sp,64
    109e:	8082                	ret
    x = -xx;
    10a0:	40b005bb          	negw	a1,a1
    neg = 1;
    10a4:	4885                	li	a7,1
    x = -xx;
    10a6:	bf8d                	j	1018 <printint+0x1a>

00000000000010a8 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
    10a8:	7119                	addi	sp,sp,-128
    10aa:	fc86                	sd	ra,120(sp)
    10ac:	f8a2                	sd	s0,112(sp)
    10ae:	f4a6                	sd	s1,104(sp)
    10b0:	f0ca                	sd	s2,96(sp)
    10b2:	ecce                	sd	s3,88(sp)
    10b4:	e8d2                	sd	s4,80(sp)
    10b6:	e4d6                	sd	s5,72(sp)
    10b8:	e0da                	sd	s6,64(sp)
    10ba:	fc5e                	sd	s7,56(sp)
    10bc:	f862                	sd	s8,48(sp)
    10be:	f466                	sd	s9,40(sp)
    10c0:	f06a                	sd	s10,32(sp)
    10c2:	ec6e                	sd	s11,24(sp)
    10c4:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
    10c6:	0005c903          	lbu	s2,0(a1)
    10ca:	18090f63          	beqz	s2,1268 <vprintf+0x1c0>
    10ce:	8aaa                	mv	s5,a0
    10d0:	8b32                	mv	s6,a2
    10d2:	00158493          	addi	s1,a1,1
  state = 0;
    10d6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
    10d8:	02500a13          	li	s4,37
      if(c == 'd'){
    10dc:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
    10e0:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
    10e4:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
    10e8:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    10ec:	00000b97          	auipc	s7,0x0
    10f0:	504b8b93          	addi	s7,s7,1284 # 15f0 <digits>
    10f4:	a839                	j	1112 <vprintf+0x6a>
        putc(fd, c);
    10f6:	85ca                	mv	a1,s2
    10f8:	8556                	mv	a0,s5
    10fa:	00000097          	auipc	ra,0x0
    10fe:	ee2080e7          	jalr	-286(ra) # fdc <putc>
    1102:	a019                	j	1108 <vprintf+0x60>
    } else if(state == '%'){
    1104:	01498f63          	beq	s3,s4,1122 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
    1108:	0485                	addi	s1,s1,1
    110a:	fff4c903          	lbu	s2,-1(s1)
    110e:	14090d63          	beqz	s2,1268 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
    1112:	0009079b          	sext.w	a5,s2
    if(state == 0){
    1116:	fe0997e3          	bnez	s3,1104 <vprintf+0x5c>
      if(c == '%'){
    111a:	fd479ee3          	bne	a5,s4,10f6 <vprintf+0x4e>
        state = '%';
    111e:	89be                	mv	s3,a5
    1120:	b7e5                	j	1108 <vprintf+0x60>
      if(c == 'd'){
    1122:	05878063          	beq	a5,s8,1162 <vprintf+0xba>
      } else if(c == 'l') {
    1126:	05978c63          	beq	a5,s9,117e <vprintf+0xd6>
      } else if(c == 'x') {
    112a:	07a78863          	beq	a5,s10,119a <vprintf+0xf2>
      } else if(c == 'p') {
    112e:	09b78463          	beq	a5,s11,11b6 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
    1132:	07300713          	li	a4,115
    1136:	0ce78663          	beq	a5,a4,1202 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
    113a:	06300713          	li	a4,99
    113e:	0ee78e63          	beq	a5,a4,123a <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
    1142:	11478863          	beq	a5,s4,1252 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
    1146:	85d2                	mv	a1,s4
    1148:	8556                	mv	a0,s5
    114a:	00000097          	auipc	ra,0x0
    114e:	e92080e7          	jalr	-366(ra) # fdc <putc>
        putc(fd, c);
    1152:	85ca                	mv	a1,s2
    1154:	8556                	mv	a0,s5
    1156:	00000097          	auipc	ra,0x0
    115a:	e86080e7          	jalr	-378(ra) # fdc <putc>
      }
      state = 0;
    115e:	4981                	li	s3,0
    1160:	b765                	j	1108 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
    1162:	008b0913          	addi	s2,s6,8
    1166:	4685                	li	a3,1
    1168:	4629                	li	a2,10
    116a:	000b2583          	lw	a1,0(s6)
    116e:	8556                	mv	a0,s5
    1170:	00000097          	auipc	ra,0x0
    1174:	e8e080e7          	jalr	-370(ra) # ffe <printint>
    1178:	8b4a                	mv	s6,s2
      state = 0;
    117a:	4981                	li	s3,0
    117c:	b771                	j	1108 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
    117e:	008b0913          	addi	s2,s6,8
    1182:	4681                	li	a3,0
    1184:	4629                	li	a2,10
    1186:	000b2583          	lw	a1,0(s6)
    118a:	8556                	mv	a0,s5
    118c:	00000097          	auipc	ra,0x0
    1190:	e72080e7          	jalr	-398(ra) # ffe <printint>
    1194:	8b4a                	mv	s6,s2
      state = 0;
    1196:	4981                	li	s3,0
    1198:	bf85                	j	1108 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
    119a:	008b0913          	addi	s2,s6,8
    119e:	4681                	li	a3,0
    11a0:	4641                	li	a2,16
    11a2:	000b2583          	lw	a1,0(s6)
    11a6:	8556                	mv	a0,s5
    11a8:	00000097          	auipc	ra,0x0
    11ac:	e56080e7          	jalr	-426(ra) # ffe <printint>
    11b0:	8b4a                	mv	s6,s2
      state = 0;
    11b2:	4981                	li	s3,0
    11b4:	bf91                	j	1108 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
    11b6:	008b0793          	addi	a5,s6,8
    11ba:	f8f43423          	sd	a5,-120(s0)
    11be:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
    11c2:	03000593          	li	a1,48
    11c6:	8556                	mv	a0,s5
    11c8:	00000097          	auipc	ra,0x0
    11cc:	e14080e7          	jalr	-492(ra) # fdc <putc>
  putc(fd, 'x');
    11d0:	85ea                	mv	a1,s10
    11d2:	8556                	mv	a0,s5
    11d4:	00000097          	auipc	ra,0x0
    11d8:	e08080e7          	jalr	-504(ra) # fdc <putc>
    11dc:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
    11de:	03c9d793          	srli	a5,s3,0x3c
    11e2:	97de                	add	a5,a5,s7
    11e4:	0007c583          	lbu	a1,0(a5)
    11e8:	8556                	mv	a0,s5
    11ea:	00000097          	auipc	ra,0x0
    11ee:	df2080e7          	jalr	-526(ra) # fdc <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    11f2:	0992                	slli	s3,s3,0x4
    11f4:	397d                	addiw	s2,s2,-1
    11f6:	fe0914e3          	bnez	s2,11de <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
    11fa:	f8843b03          	ld	s6,-120(s0)
      state = 0;
    11fe:	4981                	li	s3,0
    1200:	b721                	j	1108 <vprintf+0x60>
        s = va_arg(ap, char*);
    1202:	008b0993          	addi	s3,s6,8
    1206:	000b3903          	ld	s2,0(s6)
        if(s == 0)
    120a:	02090163          	beqz	s2,122c <vprintf+0x184>
        while(*s != 0){
    120e:	00094583          	lbu	a1,0(s2)
    1212:	c9a1                	beqz	a1,1262 <vprintf+0x1ba>
          putc(fd, *s);
    1214:	8556                	mv	a0,s5
    1216:	00000097          	auipc	ra,0x0
    121a:	dc6080e7          	jalr	-570(ra) # fdc <putc>
          s++;
    121e:	0905                	addi	s2,s2,1
        while(*s != 0){
    1220:	00094583          	lbu	a1,0(s2)
    1224:	f9e5                	bnez	a1,1214 <vprintf+0x16c>
        s = va_arg(ap, char*);
    1226:	8b4e                	mv	s6,s3
      state = 0;
    1228:	4981                	li	s3,0
    122a:	bdf9                	j	1108 <vprintf+0x60>
          s = "(null)";
    122c:	00000917          	auipc	s2,0x0
    1230:	3bc90913          	addi	s2,s2,956 # 15e8 <malloc+0x276>
        while(*s != 0){
    1234:	02800593          	li	a1,40
    1238:	bff1                	j	1214 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
    123a:	008b0913          	addi	s2,s6,8
    123e:	000b4583          	lbu	a1,0(s6)
    1242:	8556                	mv	a0,s5
    1244:	00000097          	auipc	ra,0x0
    1248:	d98080e7          	jalr	-616(ra) # fdc <putc>
    124c:	8b4a                	mv	s6,s2
      state = 0;
    124e:	4981                	li	s3,0
    1250:	bd65                	j	1108 <vprintf+0x60>
        putc(fd, c);
    1252:	85d2                	mv	a1,s4
    1254:	8556                	mv	a0,s5
    1256:	00000097          	auipc	ra,0x0
    125a:	d86080e7          	jalr	-634(ra) # fdc <putc>
      state = 0;
    125e:	4981                	li	s3,0
    1260:	b565                	j	1108 <vprintf+0x60>
        s = va_arg(ap, char*);
    1262:	8b4e                	mv	s6,s3
      state = 0;
    1264:	4981                	li	s3,0
    1266:	b54d                	j	1108 <vprintf+0x60>
    }
  }
}
    1268:	70e6                	ld	ra,120(sp)
    126a:	7446                	ld	s0,112(sp)
    126c:	74a6                	ld	s1,104(sp)
    126e:	7906                	ld	s2,96(sp)
    1270:	69e6                	ld	s3,88(sp)
    1272:	6a46                	ld	s4,80(sp)
    1274:	6aa6                	ld	s5,72(sp)
    1276:	6b06                	ld	s6,64(sp)
    1278:	7be2                	ld	s7,56(sp)
    127a:	7c42                	ld	s8,48(sp)
    127c:	7ca2                	ld	s9,40(sp)
    127e:	7d02                	ld	s10,32(sp)
    1280:	6de2                	ld	s11,24(sp)
    1282:	6109                	addi	sp,sp,128
    1284:	8082                	ret

0000000000001286 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
    1286:	715d                	addi	sp,sp,-80
    1288:	ec06                	sd	ra,24(sp)
    128a:	e822                	sd	s0,16(sp)
    128c:	1000                	addi	s0,sp,32
    128e:	e010                	sd	a2,0(s0)
    1290:	e414                	sd	a3,8(s0)
    1292:	e818                	sd	a4,16(s0)
    1294:	ec1c                	sd	a5,24(s0)
    1296:	03043023          	sd	a6,32(s0)
    129a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
    129e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
    12a2:	8622                	mv	a2,s0
    12a4:	00000097          	auipc	ra,0x0
    12a8:	e04080e7          	jalr	-508(ra) # 10a8 <vprintf>
}
    12ac:	60e2                	ld	ra,24(sp)
    12ae:	6442                	ld	s0,16(sp)
    12b0:	6161                	addi	sp,sp,80
    12b2:	8082                	ret

00000000000012b4 <printf>:

void
printf(const char *fmt, ...)
{
    12b4:	711d                	addi	sp,sp,-96
    12b6:	ec06                	sd	ra,24(sp)
    12b8:	e822                	sd	s0,16(sp)
    12ba:	1000                	addi	s0,sp,32
    12bc:	e40c                	sd	a1,8(s0)
    12be:	e810                	sd	a2,16(s0)
    12c0:	ec14                	sd	a3,24(s0)
    12c2:	f018                	sd	a4,32(s0)
    12c4:	f41c                	sd	a5,40(s0)
    12c6:	03043823          	sd	a6,48(s0)
    12ca:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
    12ce:	00840613          	addi	a2,s0,8
    12d2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
    12d6:	85aa                	mv	a1,a0
    12d8:	4505                	li	a0,1
    12da:	00000097          	auipc	ra,0x0
    12de:	dce080e7          	jalr	-562(ra) # 10a8 <vprintf>
}
    12e2:	60e2                	ld	ra,24(sp)
    12e4:	6442                	ld	s0,16(sp)
    12e6:	6125                	addi	sp,sp,96
    12e8:	8082                	ret

00000000000012ea <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
    12ea:	1141                	addi	sp,sp,-16
    12ec:	e422                	sd	s0,8(sp)
    12ee:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
    12f0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    12f4:	00000797          	auipc	a5,0x0
    12f8:	3247b783          	ld	a5,804(a5) # 1618 <freep>
    12fc:	a805                	j	132c <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
    12fe:	4618                	lw	a4,8(a2)
    1300:	9db9                	addw	a1,a1,a4
    1302:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
    1306:	6398                	ld	a4,0(a5)
    1308:	6318                	ld	a4,0(a4)
    130a:	fee53823          	sd	a4,-16(a0)
    130e:	a091                	j	1352 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
    1310:	ff852703          	lw	a4,-8(a0)
    1314:	9e39                	addw	a2,a2,a4
    1316:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
    1318:	ff053703          	ld	a4,-16(a0)
    131c:	e398                	sd	a4,0(a5)
    131e:	a099                	j	1364 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1320:	6398                	ld	a4,0(a5)
    1322:	00e7e463          	bltu	a5,a4,132a <free+0x40>
    1326:	00e6ea63          	bltu	a3,a4,133a <free+0x50>
{
    132a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
    132c:	fed7fae3          	bgeu	a5,a3,1320 <free+0x36>
    1330:	6398                	ld	a4,0(a5)
    1332:	00e6e463          	bltu	a3,a4,133a <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
    1336:	fee7eae3          	bltu	a5,a4,132a <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
    133a:	ff852583          	lw	a1,-8(a0)
    133e:	6390                	ld	a2,0(a5)
    1340:	02059813          	slli	a6,a1,0x20
    1344:	01c85713          	srli	a4,a6,0x1c
    1348:	9736                	add	a4,a4,a3
    134a:	fae60ae3          	beq	a2,a4,12fe <free+0x14>
    bp->s.ptr = p->s.ptr;
    134e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
    1352:	4790                	lw	a2,8(a5)
    1354:	02061593          	slli	a1,a2,0x20
    1358:	01c5d713          	srli	a4,a1,0x1c
    135c:	973e                	add	a4,a4,a5
    135e:	fae689e3          	beq	a3,a4,1310 <free+0x26>
  } else
    p->s.ptr = bp;
    1362:	e394                	sd	a3,0(a5)
  freep = p;
    1364:	00000717          	auipc	a4,0x0
    1368:	2af73a23          	sd	a5,692(a4) # 1618 <freep>
}
    136c:	6422                	ld	s0,8(sp)
    136e:	0141                	addi	sp,sp,16
    1370:	8082                	ret

0000000000001372 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
    1372:	7139                	addi	sp,sp,-64
    1374:	fc06                	sd	ra,56(sp)
    1376:	f822                	sd	s0,48(sp)
    1378:	f426                	sd	s1,40(sp)
    137a:	f04a                	sd	s2,32(sp)
    137c:	ec4e                	sd	s3,24(sp)
    137e:	e852                	sd	s4,16(sp)
    1380:	e456                	sd	s5,8(sp)
    1382:	e05a                	sd	s6,0(sp)
    1384:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
    1386:	02051493          	slli	s1,a0,0x20
    138a:	9081                	srli	s1,s1,0x20
    138c:	04bd                	addi	s1,s1,15
    138e:	8091                	srli	s1,s1,0x4
    1390:	0014899b          	addiw	s3,s1,1
    1394:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
    1396:	00000517          	auipc	a0,0x0
    139a:	28253503          	ld	a0,642(a0) # 1618 <freep>
    139e:	c515                	beqz	a0,13ca <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    13a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    13a2:	4798                	lw	a4,8(a5)
    13a4:	02977f63          	bgeu	a4,s1,13e2 <malloc+0x70>
    13a8:	8a4e                	mv	s4,s3
    13aa:	0009871b          	sext.w	a4,s3
    13ae:	6685                	lui	a3,0x1
    13b0:	00d77363          	bgeu	a4,a3,13b6 <malloc+0x44>
    13b4:	6a05                	lui	s4,0x1
    13b6:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
    13ba:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
    13be:	00000917          	auipc	s2,0x0
    13c2:	25a90913          	addi	s2,s2,602 # 1618 <freep>
  if(p == (char*)-1)
    13c6:	5afd                	li	s5,-1
    13c8:	a895                	j	143c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
    13ca:	00000797          	auipc	a5,0x0
    13ce:	2be78793          	addi	a5,a5,702 # 1688 <base>
    13d2:	00000717          	auipc	a4,0x0
    13d6:	24f73323          	sd	a5,582(a4) # 1618 <freep>
    13da:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
    13dc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
    13e0:	b7e1                	j	13a8 <malloc+0x36>
      if(p->s.size == nunits)
    13e2:	02e48c63          	beq	s1,a4,141a <malloc+0xa8>
        p->s.size -= nunits;
    13e6:	4137073b          	subw	a4,a4,s3
    13ea:	c798                	sw	a4,8(a5)
        p += p->s.size;
    13ec:	02071693          	slli	a3,a4,0x20
    13f0:	01c6d713          	srli	a4,a3,0x1c
    13f4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
    13f6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
    13fa:	00000717          	auipc	a4,0x0
    13fe:	20a73f23          	sd	a0,542(a4) # 1618 <freep>
      return (void*)(p + 1);
    1402:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
    1406:	70e2                	ld	ra,56(sp)
    1408:	7442                	ld	s0,48(sp)
    140a:	74a2                	ld	s1,40(sp)
    140c:	7902                	ld	s2,32(sp)
    140e:	69e2                	ld	s3,24(sp)
    1410:	6a42                	ld	s4,16(sp)
    1412:	6aa2                	ld	s5,8(sp)
    1414:	6b02                	ld	s6,0(sp)
    1416:	6121                	addi	sp,sp,64
    1418:	8082                	ret
        prevp->s.ptr = p->s.ptr;
    141a:	6398                	ld	a4,0(a5)
    141c:	e118                	sd	a4,0(a0)
    141e:	bff1                	j	13fa <malloc+0x88>
  hp->s.size = nu;
    1420:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
    1424:	0541                	addi	a0,a0,16
    1426:	00000097          	auipc	ra,0x0
    142a:	ec4080e7          	jalr	-316(ra) # 12ea <free>
  return freep;
    142e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
    1432:	d971                	beqz	a0,1406 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
    1434:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
    1436:	4798                	lw	a4,8(a5)
    1438:	fa9775e3          	bgeu	a4,s1,13e2 <malloc+0x70>
    if(p == freep)
    143c:	00093703          	ld	a4,0(s2)
    1440:	853e                	mv	a0,a5
    1442:	fef719e3          	bne	a4,a5,1434 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
    1446:	8552                	mv	a0,s4
    1448:	00000097          	auipc	ra,0x0
    144c:	b6c080e7          	jalr	-1172(ra) # fb4 <sbrk>
  if(p == (char*)-1)
    1450:	fd5518e3          	bne	a0,s5,1420 <malloc+0xae>
        return 0;
    1454:	4501                	li	a0,0
    1456:	bf45                	j	1406 <malloc+0x94>
