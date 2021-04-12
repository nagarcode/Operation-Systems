#include "../kernel/types.h"
#include "../user/user.h"
#include "../kernel/fcntl.h"
#include "../kernel/syscall.h"
//#include "../kernel/defs.h"

int main(int argc, char *argv[])
{
    fprintf(2, "just checking\n");
    // int mask;
    // mask = (1 << SYS_fork) | (1 << SYS_kill) | (1 << SYS_sbrk) | (1 << SYS_write);
    // trace(mask, getpid());
    // int pid = fork();
    // kill(pid);
    // exit(0);

    int pid = fork();
    if(pid < 0){
        printf("Fork failed\nexitting...\n");
        exit(-1);
    }
    else if(pid == 0){//child
        int exit_code = 0;
        printf("child program running...\n");
        sleep(20);
        printf("child program exitting with code %d...\n", exit_code);
        exit(exit_code);
    }
    else{//parent
        int buff[6];
        struct perf *prf = (struct perf*)buff;//malloc(6*sizeof(int));
        int status = 0;//malloc(sizeof(int));
        printf("[PARENT]: parent waiting on child to die...\n");
        int pid = wait_stat(&status, prf);
        printf("[PARENT]: pid of child = %d\n",pid);
        printf("[PARENT]: status = %d\n",status);
        exit(0);
    }
}