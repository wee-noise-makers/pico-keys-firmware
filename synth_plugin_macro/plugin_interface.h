/*
 * Copyright (c) 2020 Raspberry Pi (Trading) Ltd.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */


#ifndef _PLUGIN_INTERFACE_H_
#define _PLUGIN_INTERFACE_H_

#ifdef __cplusplus
extern "C" {
#endif

#define BITS_PER_SAMPLE        10
#define SAMPLE_BITS_TO_DISCARD (16- BITS_PER_SAMPLE)

#define RAM_BASE ((uint32_t)0x20000000)
#define SIO_BASE ((uint32_t)0xd0000000)

#define SIO_FIFO_ST_VLD 0x00000001
#define SIO_FIFO_ST_RDY 0x00000002

uint32_t volatile * sio_fifo_st = ((uint32_t *) (SIO_BASE + 0x50));
uint32_t volatile * sio_fifo_wr = ((uint32_t *) (SIO_BASE + 0x54));
uint32_t volatile * sio_fifo_rd = ((uint32_t *) (SIO_BASE + 0x58));

/*! \brief Attribute to force inlining of a function regardless of optimization level
 *  \ingroup pico_platform
 *
 *  For example my_function here will always be inlined:
 *
 *      int __force_inline my_function(int x) {
 *
 */
#if defined(__GNUC__) && __GNUC__ <= 7
#define __force_inline inline __always_inline
#else
#define __force_inline __always_inline
#endif

/*! \brief Insert a SEV instruction in to the code path.
 *  \ingroup hardware_sync

 * The SEV (send event) instruction sends an event to both cores.
 */
__force_inline static void __sev(void) {
    __asm volatile ("sev");
}

/*! \brief Insert a WFE instruction in to the code path.
 *  \ingroup hardware_sync
 *
 * The WFE (wait for event) instruction waits until one of a number of
 * events occurs, including events signalled by the SEV instruction on either core.
 */
__force_inline static void __wfe(void) {
    __asm volatile ("wfe");
}

/*! \brief Insert a WFI instruction in to the code path.
  *  \ingroup hardware_sync
*
 * The WFI (wait for interrupt) instruction waits for a interrupt to wake up the core.
 */
__force_inline static void __wfi(void) {
    __asm volatile ("wfi");
}

__force_inline static bool fifo_wready(){
    return *sio_fifo_st & SIO_FIFO_ST_RDY;
}

__force_inline static bool fifo_rvalid(){
    return *sio_fifo_st & SIO_FIFO_ST_VLD;
}

static inline void fifo_push_blocking(uint32_t data) {
    // We wait for the fifo to have some space
    while (!fifo_wready())
        continue;

    *sio_fifo_wr = data;

    // Fire off an event to the other core
    __sev();
}

static inline uint32_t fifo_pop_blocking(void) {
    // If nothing there yet, we wait for an event first,
    // to try and avoid too much busy waiting
    while (!fifo_rvalid())
        __wfe();

    return *sio_fifo_rd;
}

#ifdef __cplusplus
}
#endif

#endif /* ! _PLUGIN_INTERFACE_H_ */
