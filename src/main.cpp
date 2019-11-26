#include <protobridge.h>
#include <stdio.h>
#include <inttypes.h>

int main(int argc, char** argv)
{
    ProtoBridge hBridge;
    CreateProtoBridge(&hBridge);

    uint64_t data = 1;

    const uint32_t kNumCycles = 8;
    for (uint32_t cycleIndex = 0; cycleIndex < kNumCycles; ++cycleIndex)
    {
        data = UpdateProtoBridge(hBridge, data);

	printf("Cycle [%u] Data: %" PRIu64 "\n", cycleIndex, data);
    }

    DestroyProtoBridge(hBridge);

    return 0;
}
