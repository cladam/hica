#include <sys/stat.h>
#include <unistd.h>

long get_mtime(const char *path) {
    struct stat statbuf;
    if (stat(path, &statbuf) == -1) {
        return -1;
    }
    return statbuf.st_mtime;
}
