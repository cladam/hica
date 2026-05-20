/*
 * hica – persistent Node.js subprocess for REPL evaluation
 *
 * Manages a long-lived Node.js process with stdin/stdout pipes.
 * JS snippets are sent via stdin, output is read from stdout.
 * Protocol: code lines terminated by __HICA_EVAL_END__,
 *           output lines terminated by __HICA_EVAL_DONE__
 *
 * Unix: uses fork/pipe/exec for bidirectional communication.
 * Windows: stubs return -1 (not supported); Koka falls back to per-eval node.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

#ifdef _WIN32

/* Windows: persistent subprocess not supported — return stubs */

static kk_integer_t kk_hica_node_start(kk_string_t script_str, kk_context_t* ctx) {
  kk_string_drop(script_str, ctx);
  return kk_integer_from_int(-1, ctx);  /* not supported */
}

static kk_unit_t kk_hica_node_send_line(kk_string_t line_str, kk_context_t* ctx) {
  kk_string_drop(line_str, ctx);
  return kk_Unit;
}

static kk_string_t kk_hica_node_read_line(kk_context_t* ctx) {
  return kk_string_empty();
}

static kk_unit_t kk_hica_node_stop(kk_context_t* ctx) {
  return kk_Unit;
}

static bool kk_hica_node_alive(kk_context_t* ctx) {
  return false;
}

#else /* Unix */

#include <unistd.h>
#include <signal.h>
#include <sys/wait.h>

static FILE* hica_node_in  = NULL;
static FILE* hica_node_out = NULL;
static pid_t hica_node_pid = 0;

/*
 * Start a Node.js subprocess running the given script.
 * Sets up bidirectional pipes for communication.
 * Returns 0 on success, -1 on failure.
 */
static kk_integer_t kk_hica_node_start(kk_string_t script_str, kk_context_t* ctx) {
  const char* script = kk_string_cbuf_borrow(script_str, NULL, ctx);

  int in_pipe[2];   /* parent writes, child reads (child's stdin) */
  int out_pipe[2];  /* child writes, parent reads (child's stdout) */

  if (pipe(in_pipe) != 0 || pipe(out_pipe) != 0) {
    kk_string_drop(script_str, ctx);
    return kk_integer_from_int(-1, ctx);
  }

  pid_t pid = fork();
  if (pid < 0) {
    close(in_pipe[0]); close(in_pipe[1]);
    close(out_pipe[0]); close(out_pipe[1]);
    kk_string_drop(script_str, ctx);
    return kk_integer_from_int(-1, ctx);
  }

  if (pid == 0) {
    /* Child process */
    close(in_pipe[1]);   /* close write end of input pipe */
    close(out_pipe[0]);  /* close read end of output pipe */
    dup2(in_pipe[0], STDIN_FILENO);
    dup2(out_pipe[1], STDOUT_FILENO);
    dup2(out_pipe[1], STDERR_FILENO);
    close(in_pipe[0]);
    close(out_pipe[1]);
    execlp("node", "node", "-e", script, NULL);
    _exit(127);  /* exec failed */
  }

  /* Parent process */
  close(in_pipe[0]);   /* close read end of input pipe */
  close(out_pipe[1]);  /* close write end of output pipe */

  hica_node_in  = fdopen(in_pipe[1], "w");
  hica_node_out = fdopen(out_pipe[0], "r");
  hica_node_pid = pid;

  kk_string_drop(script_str, ctx);

  if (hica_node_in == NULL || hica_node_out == NULL) {
    return kk_integer_from_int(-1, ctx);
  }

  return kk_integer_from_int(0, ctx);
}

/*
 * Send a line to the Node.js subprocess stdin.
 */
static kk_unit_t kk_hica_node_send_line(kk_string_t line_str, kk_context_t* ctx) {
  if (hica_node_in != NULL) {
    const char* line = kk_string_cbuf_borrow(line_str, NULL, ctx);
    fputs(line, hica_node_in);
    fputc('\n', hica_node_in);
    fflush(hica_node_in);
  }
  kk_string_drop(line_str, ctx);
  return kk_Unit;
}

/*
 * Read a line from the Node.js subprocess stdout.
 * Returns the line (without trailing newline), or "" on EOF/error.
 */
static kk_string_t kk_hica_node_read_line(kk_context_t* ctx) {
  if (hica_node_out == NULL) {
    return kk_string_empty();
  }

  char buf[8192];
  kk_string_t result = kk_string_empty();
  int newline_found = 0;

  while (!newline_found && fgets(buf, sizeof(buf), hica_node_out) != NULL) {
    kk_ssize_t len = (kk_ssize_t)strlen(buf);
    if (len > 0 && buf[len - 1] == '\n') {
      newline_found = 1;
      buf[--len] = '\0';
      /* Also strip \r if present */
      if (len > 0 && buf[len - 1] == '\r') {
        buf[--len] = '\0';
      }
    }
    kk_string_t chunk = kk_string_alloc_from_qutf8n(len, buf, ctx);
    result = kk_string_cat(result, chunk, ctx);
  }

  return result;
}

/*
 * Stop the Node.js subprocess.
 */
static kk_unit_t kk_hica_node_stop(kk_context_t* ctx) {
  if (hica_node_in != NULL) {
    fclose(hica_node_in);
    hica_node_in = NULL;
  }
  if (hica_node_out != NULL) {
    fclose(hica_node_out);
    hica_node_out = NULL;
  }
  if (hica_node_pid > 0) {
    kill(hica_node_pid, SIGTERM);
    waitpid(hica_node_pid, NULL, 0);
    hica_node_pid = 0;
  }
  return kk_Unit;
}

/*
 * Check if the subprocess is still running.
 */
static bool kk_hica_node_alive(kk_context_t* ctx) {
  if (hica_node_pid <= 0) return false;
  int status;
  pid_t result = waitpid(hica_node_pid, &status, WNOHANG);
  if (result == 0) return true;   /* still running */
  hica_node_pid = 0;              /* exited */
  return false;
}

#endif /* _WIN32 */

/*
 * Platform-independent pipe mode flag.
 * Set to 1 after a successful node-start, 0 otherwise.
 */
static int hica_pipe_mode = 0;

static bool kk_hica_pipe_mode(kk_context_t* ctx) {
  return hica_pipe_mode != 0;
}

static kk_unit_t kk_hica_set_pipe_mode(bool v, kk_context_t* ctx) {
  hica_pipe_mode = v ? 1 : 0;
  return kk_Unit;
}

/*
 * Platform-independent fallback JS accumulator.
 * Stores preamble + definitions for file-based REPL evaluation.
 */
static char*  hica_fb_buf = NULL;
static size_t hica_fb_len = 0;
static size_t hica_fb_cap = 0;

static kk_string_t kk_hica_fallback_js(kk_context_t* ctx) {
  if (hica_fb_buf == NULL || hica_fb_len == 0) return kk_string_empty();
  return kk_string_alloc_from_qutf8n((kk_ssize_t)hica_fb_len, hica_fb_buf, ctx);
}

static kk_unit_t kk_hica_fallback_js_clear(kk_context_t* ctx) {
  hica_fb_len = 0;
  return kk_Unit;
}

static kk_unit_t kk_hica_fallback_js_append(kk_string_t s, kk_context_t* ctx) {
  kk_ssize_t slen;
  const char* buf = kk_string_cbuf_borrow(s, &slen, ctx);
  size_t need = hica_fb_len + (size_t)slen;
  if (need > hica_fb_cap) {
    size_t new_cap = (need < 4096) ? 4096 : need * 2;
    hica_fb_buf = (char*)realloc(hica_fb_buf, new_cap);
    hica_fb_cap = new_cap;
  }
  memcpy(hica_fb_buf + hica_fb_len, buf, (size_t)slen);
  hica_fb_len = need;
  kk_string_drop(s, ctx);
  return kk_Unit;
}
