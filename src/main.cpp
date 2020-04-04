#include <protobridge.h>
#include <stdio.h>
#include <inttypes.h>

enum class RegisterType : uint64_t
{
    ICP_Enable = 0,
    ICP_Halted,
    UART_TX,
    UART_RX
};

size_t MakeRegAddr(RegisterType regType)
{
    return (static_cast<uint64_t>(regType) | 0x8000000000000000ull);
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

    for (uint32_t i = 0; i < 26; ++i)
    {
        // Send the test byte
        uint64_t txTestByte = 'A' + i;
        WriteProtoBridgeMemory(hBridge, &txTestByte, sizeof(txTestByte), MakeRegAddr(RegisterType::UART_TX));

        // Read the test byte
        uint64_t rxTestByte = 0;
        ReadProtoBridgeMemory(hBridge, MakeRegAddr(RegisterType::UART_RX), sizeof(rxTestByte), &rxTestByte);

        printf("Sent: %c, Received: %c\n", static_cast<char>(txTestByte), static_cast<char>(rxTestByte));
    }

    // Upload initial memory
    WriteProtoBridgeMemory(hBridge, pMemory, sizeof(pMemory), 0);

    // Enable the IntCode Processor
    uint64_t enableIcp = 1;
    WriteProtoBridgeMemory(hBridge, &enableIcp, sizeof(enableIcp), MakeRegAddr(RegisterType::ICP_Enable));

    const uint64_t startCycles = QueryProtoBridgeCycleCount(hBridge);

    uint64_t isHalted = 0;

    do
    {
        ClockProtoBridge(hBridge);

        ReadProtoBridgeMemory(hBridge, MakeRegAddr(RegisterType::ICP_Halted), sizeof(isHalted), &isHalted);
    } while (isHalted == 0);

    const uint64_t endCycles = QueryProtoBridgeCycleCount(hBridge);

    // Disable the IntCode Processor
    enableIcp = 0;
    WriteProtoBridgeMemory(hBridge, &enableIcp, sizeof(enableIcp), MakeRegAddr(RegisterType::ICP_Enable));

    // Read back final memory
    ReadProtoBridgeMemory(hBridge, 0, sizeof(pMemory), pMemory);

    const uint32_t numCycles = static_cast<uint32_t>(endCycles - startCycles);

    printf("Finished in %u Cycles\n", numCycles);

    printf("Final Memory[%u]: {\n", static_cast<uint32_t>(kNumQwords));

    for (size_t qwordIndex = 0; qwordIndex < kNumQwords; ++qwordIndex)
    {
        printf("%" PRIu64 ",", pMemory[qwordIndex]);
    }
    printf("\n}\n");

    DestroyProtoBridge(hBridge);

    return 0;
}
