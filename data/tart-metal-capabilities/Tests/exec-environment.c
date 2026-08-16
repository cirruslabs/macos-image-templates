#include <assert.h>
#include <mach-o/dyld.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static pid_t startChild(const char *executable, const char *library, const char *family) {
    pid_t child = fork();
    assert(child >= 0);
    if (child == 0) {
        char *libraryAssignment = NULL;
        char *familyAssignment = NULL;
        assert(asprintf(&libraryAssignment, "DYLD_INSERT_LIBRARIES=%s", library) >= 0);
        assert(asprintf(&familyAssignment, "TART_METAL_APPLE_FAMILY_MAX=%s", family) >= 0);
        execl("/usr/bin/env", "env", libraryAssignment, familyAssignment,
              executable, family, "child", NULL);
        _exit(1);
    }
    return child;
}

int main(int argc, char **argv) {
    assert(argc >= 2);
    const char *library = getenv("DYLD_INSERT_LIBRARIES");
    const char *family = getenv("TART_METAL_APPLE_FAMILY_MAX");
    const char *memory = getenv("TART_METAL_MAX_THREADGROUP_MEMORY");
    int loaded = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        if (strstr(_dyld_get_image_name(i), "/TartMetalCapabilities.dylib")) loaded = 1;
    }
    if (strcmp(argv[1], "stock") == 0) {
        assert(!library && !family && !memory && !loaded);
        puts("stock process without injection: OK");
        return 0;
    }
    assert(library && family && memory);
    assert(strcmp(family, argv[1]) == 0);
    assert(strcmp(memory, "65536") == 0);
    assert(loaded);
    if (argc == 3) return 0;

    // Concurrent workloads must get independent overrides while their parent
    // retains its explicit opt-in. Exercise the documented /usr/bin/env path.
    pid_t children[] = {
        startChild(argv[0], library, "1008"),
        startChild(argv[0], library, "0"),
    };
    for (size_t i = 0; i < sizeof(children) / sizeof(children[0]); i++) {
        int status = 0;
        assert(waitpid(children[i], &status, 0) == children[i]);
        assert(WIFEXITED(status) && WEXITSTATUS(status) == 0);
    }
    assert(strcmp(getenv("TART_METAL_APPLE_FAMILY_MAX"), argv[1]) == 0);
    puts("per-process injection and overrides: OK");
    return 0;
}
