# Register map

Created with [Corsair](https://github.com/esynr3z/corsair) v1.0.2.dev0+894dec23.

## Conventions

| Access mode | Description               |
| :---------- | :------------------------ |
| rw          | Read and Write            |
| rw1c        | Read and Write 1 to Clear |
| rw1s        | Read and Write 1 to Set   |
| ro          | Read Only                 |
| roc         | Read Only to Clear        |
| roll        | Read Only / Latch Low     |
| rolh        | Read Only / Latch High    |
| wo          | Write only                |
| wosc        | Write Only / Self Clear   |

## Register map summary

Base address: 0x00000000

| Name                     | Address    | Description |
| :---                     | :---       | :---        |
| [DEBUG_CR](#debug_cr)    | 0xf0       | DMA Control |
| [DEBUG_SR](#debug_sr)    | 0xf4       | DMA Status |
| [DEBUG_MM2S_ADDR](#debug_mm2s_addr) | 0xf8       | MM2S Start address |
| [DEBUG_S2MM_ADDR](#debug_s2mm_addr) | 0xfc       | S2MM Start address |

## DEBUG_CR

DMA Control

Address offset: 0xf0

Reset value: 0x00000000

![debug_cr](md_img/debug_cr.svg)

| Name             | Bits   | Mode            | Reset      | Description |
| :---             | :---   | :---            | :---       | :---        |
| -                | 31:29  | -               | 0x0        | Reserved |
| S2MM_START       | 28     | rw              | 0x0        | Start read transaction |
| -                | 27     | -               | 0x0        | Reserved |
| S2MM_SIZE        | 26:24  | rw              | 0x0        | The number of bytes in a transfer must be equal to the data bus width |
| S2MM_LEN         | 23:16  | rw              | 0x00       | The burst length |
| -                | 15:13  | -               | 0x0        | Reserved |
| MM2S_START       | 12     | rw              | 0x0        | Start read transaction |
| -                | 11     | -               | 0x0        | Reserved |
| MM2S_SIZE        | 10:8   | rw              | 0x0        | The number of bytes in a transfer must be equal to the data bus width |
| MM2S_LEN         | 7:0    | rw              | 0x00       | The burst length |

Back to [Register map](#register-map-summary).

## DEBUG_SR

DMA Status

Address offset: 0xf4

Reset value: 0x00000000

![debug_sr](md_img/debug_sr.svg)

| Name             | Bits   | Mode            | Reset      | Description |
| :---             | :---   | :---            | :---       | :---        |
| -                | 31:2   | -               | 0x0000000  | Reserved |
| S2MM_BUSY        | 1      | ro              | 0x0        | Write transaction in process |
| MM2S_BUSY        | 0      | ro              | 0x0        | Read transaction in process |

Back to [Register map](#register-map-summary).

## DEBUG_MM2S_ADDR

MM2S Start address

Address offset: 0xf8

Reset value: 0x00000000

![debug_mm2s_addr](md_img/debug_mm2s_addr.svg)

| Name             | Bits   | Mode            | Reset      | Description |
| :---             | :---   | :---            | :---       | :---        |
| ADDR             | 31:0   | rw              | 0x00000000 | Indicates the Start Address |

Back to [Register map](#register-map-summary).

## DEBUG_S2MM_ADDR

S2MM Start address

Address offset: 0xfc

Reset value: 0x00000000

![debug_s2mm_addr](md_img/debug_s2mm_addr.svg)

| Name             | Bits   | Mode            | Reset      | Description |
| :---             | :---   | :---            | :---       | :---        |
| ADDR             | 31:0   | rw              | 0x00000000 | Indicates the Start Address |

Back to [Register map](#register-map-summary).
