#include <stdlib.h>
#include <unistd.h>

int main(int argc, char **argv)
{
    if (argc != 2)
        return 2;
    char *end;
    long seconds = strtol(argv[1], &end, 10);
    if (end == argv[1] || *end || seconds < 0 || seconds > 60)
        return 2;
    unsigned int remaining = (unsigned int)seconds;
    while (remaining)
        remaining = sleep(remaining);
    return 0;
}
