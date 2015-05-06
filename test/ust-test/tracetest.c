#include <stdio.h>

#include "tracetest-tp.h"

int main(int argc, char* argv[])
{
	int i;
        int max = 1000;

        if (argc >= 2) {
	  max = atoi(argv[1]);
        }

        printf("max loops = %i\n", max);
        for (i = 0; i < max; i++) {
	  tracepoint(tracetest, first_tp, i, "test");
        }

        return 0;
}
