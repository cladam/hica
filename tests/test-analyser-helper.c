#include <kklib.h>

#if defined(_WIN32)
#include <windows.h>
void my_process_exit(int code) {
  ExitProcess(code);
}
#else
#include <unistd.h>
void my_process_exit(int code) {
  _exit(code);
}
#endif

static kk_box_t kept_alive[100];
static int kept_alive_count = 0;

void hica_keep_alive(kk_box_t box, kk_context_t* ctx) {
  if (kept_alive_count < 100) {
    kept_alive[kept_alive_count++] = kk_box_dup(box, ctx);
  }
}
