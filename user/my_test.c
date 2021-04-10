#include "../kernel/types.h"
#include "../user/user.h"
#include "../kernel/fcntl.h"
#include "../kernel/syscall.h"
//#include "../kernel/defs.h"

int main(int argc, char *argv[])
{
    //fprintf(2, "just checking\n");
    int mask;
    mask = (1 << SYS_fork) | (1 << SYS_kill) | (1 << SYS_sbrk) | (1 << SYS_write);
    trace(mask, getpid());
    int pid = fork();
    kill(pid);
    exit(0);
}