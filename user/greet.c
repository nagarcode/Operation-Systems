#include "../kernel/types.h"
#include "../user/user.h"
#include "../kernel/fcntl.h"

int main( int argc, char *argv[] )  {

   if( argc == 1 ) {
      fprintf(2,"No args supplied\n");
   }
   else if( argc == 2 ) {
      fprintf(2,"Hello, %s.\n",argv[1]);
   }
   else {
      fprintf(2,"received %d args instead of 1.\n", (argc-1));
   }
   exit(0);
}