#include <protobridge.h>
#include <stdio.h>
#include <inttypes.h>

int main(int argc, char** argv)
{
    uint64_t pMemory[1] = { 2 };

    ProtoBridge hBridge;
    CreateProtoBridge(&hBridge, &pMemory, sizeof(pMemory));

    const uint32_t kNumCycles = 8;
    for (uint32_t cycleIndex = 0; cycleIndex < kNumCycles; ++cycleIndex)
    {
        UpdateProtoBridge(hBridge);

        printf("Cycle [%u] Data: %" PRIu64 "\n", cycleIndex, pMemory[0]);
    }

    DestroyProtoBridge(hBridge);

    return 0;
}
