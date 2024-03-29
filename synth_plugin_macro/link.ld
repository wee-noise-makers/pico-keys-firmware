/* This is a ARM specific version of this file */

/* This script replaces ld's default linker script, providing the
   appropriate memory map and output format. */

SEARCH_DIR(.)
__DYNAMIC  =  0;

_DEFAULT_STACK_SIZE = 0x1000;

ENTRY(Reset_Handler);

MEMORY
{
  RAM (rwx) : ORIGIN = 0x2000C800, LENGTH = 0x33800
  SCRATCH_X (rwx) : ORIGIN = 0x20040000, LENGTH = 0x1000
}

/*
 * Boot memory (.text, .ro_data, interrupt vector): RAM
 * Main RAM memory (.data, .bss, stacks, interrupt stacks): RAM
 */

SECTIONS
{

  /*******/
  /* RAM */
  /*******/
  .text :
  {
    KEEP (*(.vectors))
    *(.text .text.* .gnu.linkonce.t*)
    *(.gnu.warning)
    KEEP (*(.init))
    KEEP (*(.fini))
  } > RAM

  .ARM.extab   : { *(.ARM.extab* .gnu.linkonce.armextab.*) } > RAM
  /* .ARM.exidx is 4-bytes aligned, so __exidx_start needs to be
     aligned too. Note that assigning the location counter also makes
     ld attach the following symbols to the next section (instead of the
     previous section which is the default), so will properly
     consider the location counter of .ARM.exidx for __exidx_start and
      __exidx_end and not the previous section's one. */
  . = ALIGN(0x4);
  PROVIDE_HIDDEN (__exidx_start = .);
  .ARM.exidx   : { *(.ARM.exidx* .gnu.linkonce.armexidx.*) } > RAM
  PROVIDE_HIDDEN (__exidx_end = .);

  .preinit_array     :
  {
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
  } > RAM

  .init_array :
  {
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
  } > RAM

  .fini_array :
  {
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
  } > RAM

  .rodata :
  {
    *(.lit)
    *(.rodata .rodata.* .gnu.linkonce.r*)
    . = ALIGN(0x4);
    __rom_end = .;
  } > RAM
  /**************/
  /* End of RAM */
  /**************/

  /*******/
  /* RAM */
  /*******/
  __data_load = LOADADDR(.data);
  .data :
  {
    __data_start = .;
    *(.data .data.* .gnu.linkonce.d*)

    /* Ensure that the end of the data section is always word aligned.
       Initial values are stored in 4-bytes blocks so we must guarantee
       that these blocks do not fall out the section (otherwise they are
       truncated and the initial data for the last block are lost). */

    . = ALIGN(0x4);
    __data_end = .;
  } > RAM AT> RAM
  __data_words = (__data_end - __data_start) >> 2;

  .bss (NOLOAD): {
   . = ALIGN(0x8);
   __bss_start = .;

   *(.bss .bss.*)
   *(COMMON)

   . = ALIGN(0x8);    /* Align the stack to 64 bits */
   __bss_end = .;


   _end = .;
   __heap_start = .;
   __heap_end = ORIGIN(RAM) + LENGTH(RAM);
  } > RAM
  __bss_words = (__bss_end - __bss_start) >> 2;
  /**************/
  /* End of RAM */
  /**************/

  /*************/
  /* SCRATCH_X */
  /*************/
  __SCRATCH_X_data_load = LOADADDR(.SCRATCH_X_data);
  .SCRATCH_X_data :
  {
    __SCRATCH_X_data_start = .;
    *(.SCRATCH_X_data .SCRATCH_X_data.*)

    /* Ensure that the end of the data section is always word aligned.
       Initial values are stored in 4-bytes blocks so we must guarantee
       that these blocks do not fall out the section (otherwise they are
       truncated and the initial data for the last block are lost). */

    . = ALIGN(0x4);
    __SCRATCH_X_data_end = .;
  } >  SCRATCH_X AT> RAM
  __SCRATCH_X_data_words = (__SCRATCH_X_data_end - __SCRATCH_X_data_start) >> 2;

  .SCRATCH_X_bss (NOLOAD): {
    . = ALIGN(0x8);
    __SCRATCH_X_bss_start = .;

    *(.SCRATCH_X_bss .SCRATCH_X_bss.*)

    __interrupt_stack_start = .;
    *(.interrupt_stacks)
    . = ALIGN(0x8);
    __interrupt_stack_end = .;

    __stack_start = .;
    . += DEFINED (__stack_size) ? __stack_size : _DEFAULT_STACK_SIZE;
    . = ALIGN(0x8);
    __stack_end = .;

    __SCRATCH_X_bss_end = .;
    __SCRATCH_X_heap_start = .;
    __SCRATCH_X_heap_end = ORIGIN(SCRATCH_X) + LENGTH(SCRATCH_X);
  } > SCRATCH_X
  __SCRATCH_X_bss_words = (__SCRATCH_X_bss_end - __SCRATCH_X_bss_start) >> 2;
  /********************/
  /* End of SCRATCH_X */
  /********************/

  /* DWARF debug sections.
     Symbols in the DWARF debugging sections are relative to the beginning
     of the section so we begin them at 0.  */
  /* DWARF 1 */
  .debug          0 : { *(.debug) }
  .line           0 : { *(.line) }
  /* GNU DWARF 1 extensions */
  .debug_srcinfo  0 : { *(.debug_srcinfo) }
  .debug_sfnames  0 : { *(.debug_sfnames) }
  /* DWARF 1.1 and DWARF 2 */
  .debug_aranges  0 : { *(.debug_aranges) }
  .debug_pubnames 0 : { *(.debug_pubnames) }
  /* DWARF 2 */
  .debug_info     0 : { *(.debug_info .gnu.linkonce.wi.*) }
  .debug_abbrev   0 : { *(.debug_abbrev) }
  .debug_line     0 : { *(.debug_line) }
  .debug_frame    0 : { *(.debug_frame) }
  .debug_str      0 : { *(.debug_str) }
  .debug_loc      0 : { *(.debug_loc) }
  .debug_macinfo  0 : { *(.debug_macinfo) }
  /* DWARF 3 */
  .debug_pubtypes 0 : { *(.debug_pubtypes) }
  .debug_ranges   0 : { *(.debug_ranges) }
  .gnu.attributes 0 : { KEEP (*(.gnu.attributes)) }
  /DISCARD/ : { *(.note.GNU-stack) *(.gnu_debuglink) *(.gnu.lto_*) }
}