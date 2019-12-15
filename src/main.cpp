#include <protobridge.h>
#include <stdio.h>
#include <inttypes.h>

size_t MakeRegAddr(size_t regAddr)
{
    return (regAddr | 0x8000000000000000ull);
}

int main(int argc, char** argv)
{
    uint64_t pMemory[] =
    {
        1,12,2,3,1,1,2,3,1,3,4,3,1,5,0,3,2,1,10,19,2,9,19,23,2,23,10,27,1,6,27,31,1,31,6,35,2,35,10,39,1,39,5,43,2,6,43,47,2,47,10,51,1,51,6,55,1,55,6,59,1,9,59,63,1,63,9,67,1,67,6,71,2,71,13,75,1,75,5,79,1,79,9,83,2,6,83,87,1,87,5,91,2,6,91,95,1,95,9,99,2,6,99,103,1,5,103,107,1,6,107,111,1,111,10,115,2,115,13,119,1,119,6,123,1,123,2,127,1,127,5,0,99,2,14,0,0
    };

    const size_t kNumQwords = static_cast<size_t>(sizeof(pMemory) / sizeof(pMemory[0]));

    ProtoBridge hBridge;
    CreateProtoBridge(&hBridge);

    // Upload initial memory
    WriteProtoBridgeMemory(hBridge, pMemory, sizeof(pMemory), 0);

    uint32_t numCycles = 0;
    uint64_t isHalted = 0;

    do
    {
        ClockProtoBridge(hBridge);
        ++numCycles;

        ReadProtoBridgeMemory(hBridge, MakeRegAddr(0), sizeof(isHalted), &isHalted);
    } while (isHalted == 0);

    // Read back final memory
    ReadProtoBridgeMemory(hBridge, 0, sizeof(pMemory), pMemory);

    // Subtract a single cycle because it takes a cycle to detect the halted state change
    printf("Finished in %u Cycles\n", numCycles - 1);

    printf("Final Memory[%u]: {\n", static_cast<uint32_t>(kNumQwords));

    for (size_t qwordIndex = 0; qwordIndex < kNumQwords; ++qwordIndex)
    {
        printf("%" PRIu64 ",", pMemory[qwordIndex]);
    }
    printf("\n}\n");

    DestroyProtoBridge(hBridge);

    return 0;
}
