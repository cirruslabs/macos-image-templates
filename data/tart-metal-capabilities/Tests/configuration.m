#import "../Sources/TartMetalCapabilities.m"

#include <assert.h>
#include <stdio.h>
#include <string.h>

static void resetConfiguration(void) {
    unsetenv("TART_METAL_APPLE_FAMILY_MAX");
    unsetenv("TART_METAL_MAX_THREADGROUP_MEMORY");
    unsetenv("TART_METAL_RECOMMENDED_WORKING_SET_SIZE");
    unsetenv("LUME_METAL_APPLE_FAMILY_MAX");
    gConfiguration = (TartMetalConfiguration){0};
}

int main(int argc, const char *argv[]) {
    // In this mode, check the configuration loaded by the real constructor
    // before main(), as it would be for a newly executed workload.
    if (argc == 2) {
        NSUInteger expected = (NSUInteger)strtoull(argv[1], NULL, 10);
        assert(gConfiguration.enabled == (expected != 0));
        assert(gConfiguration.appleFamilyMax == expected);
        return 0;
    }

    resetConfiguration();
    assert(!loadConfiguration());
    setenv("LUME_METAL_APPLE_FAMILY_MAX", "1009", 1);
    assert(!loadConfiguration());

    const char *invalidFamilies[] = {"", "0", "1000", "2000", "-1", "1009x"};
    for (size_t i = 0; i < sizeof(invalidFamilies) / sizeof(invalidFamilies[0]); i++) {
        resetConfiguration();
        setenv("TART_METAL_APPLE_FAMILY_MAX", invalidFamilies[i], 1);
        assert(!loadConfiguration());
        assert(!gConfiguration.enabled);
    }

    resetConfiguration();
    setenv("TART_METAL_APPLE_FAMILY_MAX", "1009", 1);
    assert(loadConfiguration());
    assert(gConfiguration.appleFamilyMax == 1009);
    assert(gConfiguration.maxThreadgroupMemory == 65536);
    assert(!gConfiguration.hasRecommendedWorkingSetSize);

    resetConfiguration();
    setenv("TART_METAL_APPLE_FAMILY_MAX", "1999", 1);
    setenv("TART_METAL_MAX_THREADGROUP_MEMORY", "32768", 1);
    setenv("TART_METAL_RECOMMENDED_WORKING_SET_SIZE", "1073741824", 1);
    assert(loadConfiguration());
    assert(gConfiguration.appleFamilyMax == 1999);
    assert(gConfiguration.maxThreadgroupMemory == 32768);
    assert(gConfiguration.hasRecommendedWorkingSetSize);
    assert(gConfiguration.recommendedWorkingSetSize == 1073741824);

    resetConfiguration();
    setenv("TART_METAL_APPLE_FAMILY_MAX", "1009", 1);
    setenv("TART_METAL_MAX_THREADGROUP_MEMORY", "invalid", 1);
    assert(!loadConfiguration());
    unsetenv("TART_METAL_MAX_THREADGROUP_MEMORY");
    setenv("TART_METAL_RECOMMENDED_WORKING_SET_SIZE", "invalid", 1);
    assert(!loadConfiguration());

    resetConfiguration();
    puts("configuration: OK");
    return 0;
}
