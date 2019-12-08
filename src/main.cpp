#include <protobridge.h>
#include <stdio.h>
#include <inttypes.h>

int main(int argc, char** argv)
{
    uint32_t pMemory[] =
    {
        1,12,2,3,1,1,2,3,1,3,4,3,1,5,0,3,2,1,10,19,2,9,19,23,2,23,10,27,1,6,27,31,1,31,6,35,2,35,10,39,1,39,5,43,2,6,43,47,2,47,10,51,1,51,6,55,1,55,6,59,1,9,59,63,1,63,9,67,1,67,6,71,2,71,13,75,1,75,5,79,1,79,9,83,2,6,83,87,1,87,5,91,2,6,91,95,1,95,9,99,2,6,99,103,1,5,103,107,1,6,107,111,1,111,10,115,2,115,13,119,1,119,6,123,1,123,2,127,1,127,5,0,99,2,14,0,0
    };

    ProtoBridge hBridge;
    CreateProtoBridge(&hBridge, &pMemory, sizeof(pMemory));

    const uint32_t kNumCycles = 384;
    for (uint32_t cycleIndex = 0; cycleIndex < kNumCycles; ++cycleIndex)
    {
        UpdateProtoBridge(hBridge);

        //printf("Cycle [%u] Data: %u\n", cycleIndex, pMemory[8]);
    }

    const uint32_t kNumDwords = static_cast<uint32_t>(sizeof(pMemory) / sizeof(pMemory[0]));
    printf("Final Memory[%u]: {\n", kNumDwords);

    for (uint32_t dwordIndex = 0; dwordIndex < (sizeof(pMemory) / sizeof(pMemory[0])); ++dwordIndex)
    {
        printf("%u,", pMemory[dwordIndex]);
    }
    printf("\n}\n");

    DestroyProtoBridge(hBridge);

    return 0;
}
