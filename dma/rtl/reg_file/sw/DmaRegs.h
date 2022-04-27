// Created with Corsair v1.0.2.dev0+894dec23
#ifndef __DMAREGS_H
#define __DMAREGS_H

#define __I  volatile const // 'read only' permissions
#define __O  volatile       // 'write only' permissions
#define __IO volatile       // 'read / write' permissions

#include "stdint.h"

#ifdef __cplusplus
extern "C" {
#endif

#define DMA_CSR_BASE_ADDR 0x0

// DEBUG_CR - DMA Control
#define DMA_CSR_DEBUG_CR_ADDR 0xf0
#define DMA_CSR_DEBUG_CR_RESET 0x0
typedef struct {
    uint32_t MM2S_LEN : 8; // The burst length
    uint32_t MM2S_SIZE : 3; // The number of bytes in a transfer must be equal to the data bus width
    uint32_t :1; // reserved
    uint32_t MM2S_START : 1; // Start read transaction
    uint32_t :3; // reserved
    uint32_t S2MM_LEN : 8; // The burst length
    uint32_t S2MM_SIZE : 3; // The number of bytes in a transfer must be equal to the data bus width
    uint32_t :1; // reserved
    uint32_t S2MM_START : 1; // Start read transaction
} dma_csr_debug_cr_t;

// DEBUG_CR.MM2S_LEN - The burst length
#define DMA_CSR_DEBUG_CR_MM2S_LEN_WIDTH 8
#define DMA_CSR_DEBUG_CR_MM2S_LEN_LSB 0
#define DMA_CSR_DEBUG_CR_MM2S_LEN_MASK 0xf0
#define DMA_CSR_DEBUG_CR_MM2S_LEN_RESET 0x0

// DEBUG_CR.MM2S_SIZE - The number of bytes in a transfer must be equal to the data bus width
#define DMA_CSR_DEBUG_CR_MM2S_SIZE_WIDTH 3
#define DMA_CSR_DEBUG_CR_MM2S_SIZE_LSB 8
#define DMA_CSR_DEBUG_CR_MM2S_SIZE_MASK 0xf0
#define DMA_CSR_DEBUG_CR_MM2S_SIZE_RESET 0x0

// DEBUG_CR.MM2S_START - Start read transaction
#define DMA_CSR_DEBUG_CR_MM2S_START_WIDTH 1
#define DMA_CSR_DEBUG_CR_MM2S_START_LSB 12
#define DMA_CSR_DEBUG_CR_MM2S_START_MASK 0xf0
#define DMA_CSR_DEBUG_CR_MM2S_START_RESET 0x0

// DEBUG_CR.S2MM_LEN - The burst length
#define DMA_CSR_DEBUG_CR_S2MM_LEN_WIDTH 8
#define DMA_CSR_DEBUG_CR_S2MM_LEN_LSB 16
#define DMA_CSR_DEBUG_CR_S2MM_LEN_MASK 0xf0
#define DMA_CSR_DEBUG_CR_S2MM_LEN_RESET 0x0

// DEBUG_CR.S2MM_SIZE - The number of bytes in a transfer must be equal to the data bus width
#define DMA_CSR_DEBUG_CR_S2MM_SIZE_WIDTH 3
#define DMA_CSR_DEBUG_CR_S2MM_SIZE_LSB 24
#define DMA_CSR_DEBUG_CR_S2MM_SIZE_MASK 0xf0
#define DMA_CSR_DEBUG_CR_S2MM_SIZE_RESET 0x0

// DEBUG_CR.S2MM_START - Start read transaction
#define DMA_CSR_DEBUG_CR_S2MM_START_WIDTH 1
#define DMA_CSR_DEBUG_CR_S2MM_START_LSB 28
#define DMA_CSR_DEBUG_CR_S2MM_START_MASK 0xf0
#define DMA_CSR_DEBUG_CR_S2MM_START_RESET 0x0

// DEBUG_SR - DMA Status
#define DMA_CSR_DEBUG_SR_ADDR 0xf4
#define DMA_CSR_DEBUG_SR_RESET 0x0
typedef struct {
    uint32_t MM2S_BUSY : 1; // Read transaction in process
    uint32_t S2MM_BUSY : 1; // Write transaction in process
} dma_csr_debug_sr_t;

// DEBUG_SR.MM2S_BUSY - Read transaction in process
#define DMA_CSR_DEBUG_SR_MM2S_BUSY_WIDTH 1
#define DMA_CSR_DEBUG_SR_MM2S_BUSY_LSB 0
#define DMA_CSR_DEBUG_SR_MM2S_BUSY_MASK 0xf4
#define DMA_CSR_DEBUG_SR_MM2S_BUSY_RESET 0x0

// DEBUG_SR.S2MM_BUSY - Write transaction in process
#define DMA_CSR_DEBUG_SR_S2MM_BUSY_WIDTH 1
#define DMA_CSR_DEBUG_SR_S2MM_BUSY_LSB 1
#define DMA_CSR_DEBUG_SR_S2MM_BUSY_MASK 0xf4
#define DMA_CSR_DEBUG_SR_S2MM_BUSY_RESET 0x0

// DEBUG_MM2S_ADDR - MM2S Start address
#define DMA_CSR_DEBUG_MM2S_ADDR_ADDR 0xf8
#define DMA_CSR_DEBUG_MM2S_ADDR_RESET 0x0
typedef struct {
    uint32_t ADDR : 32; // Indicates the Start Address
} dma_csr_debug_mm2s_addr_t;

// DEBUG_MM2S_ADDR.ADDR - Indicates the Start Address
#define DMA_CSR_DEBUG_MM2S_ADDR_ADDR_WIDTH 32
#define DMA_CSR_DEBUG_MM2S_ADDR_ADDR_LSB 0
#define DMA_CSR_DEBUG_MM2S_ADDR_ADDR_MASK 0xf8
#define DMA_CSR_DEBUG_MM2S_ADDR_ADDR_RESET 0x0

// DEBUG_S2MM_ADDR - S2MM Start address
#define DMA_CSR_DEBUG_S2MM_ADDR_ADDR 0xfc
#define DMA_CSR_DEBUG_S2MM_ADDR_RESET 0x0
typedef struct {
    uint32_t ADDR : 32; // Indicates the Start Address
} dma_csr_debug_s2mm_addr_t;

// DEBUG_S2MM_ADDR.ADDR - Indicates the Start Address
#define DMA_CSR_DEBUG_S2MM_ADDR_ADDR_WIDTH 32
#define DMA_CSR_DEBUG_S2MM_ADDR_ADDR_LSB 0
#define DMA_CSR_DEBUG_S2MM_ADDR_ADDR_MASK 0xfc
#define DMA_CSR_DEBUG_S2MM_ADDR_ADDR_RESET 0x0


// Register map structure
typedef struct {
    __IO uint32_t RESERVED0[60];
    union {
        __IO uint32_t DEBUG_CR; // DMA Control
        __IO dma_csr_debug_cr_t DEBUG_CR_bf; // Bit access for DEBUG_CR register
    };
    union {
        __I uint32_t DEBUG_SR; // DMA Status
        __I dma_csr_debug_sr_t DEBUG_SR_bf; // Bit access for DEBUG_SR register
    };
    union {
        __IO uint32_t DEBUG_MM2S_ADDR; // MM2S Start address
        __IO dma_csr_debug_mm2s_addr_t DEBUG_MM2S_ADDR_bf; // Bit access for DEBUG_MM2S_ADDR register
    };
    union {
        __IO uint32_t DEBUG_S2MM_ADDR; // S2MM Start address
        __IO dma_csr_debug_s2mm_addr_t DEBUG_S2MM_ADDR_bf; // Bit access for DEBUG_S2MM_ADDR register
    };
} dma_csr_t;

#define DMA_CSR ((dma_csr_t*)(DMA_CSR_BASE_ADDR))

#ifdef __cplusplus
}
#endif

#endif /* __DMAREGS_H */