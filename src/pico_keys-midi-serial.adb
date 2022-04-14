with HAL; use HAL;

with Cortex_M.NVIC;
with RP2040_SVD.Interrupts;

with RP.Device;
with RP.UART;
with RP.GPIO; use RP.GPIO;

with BBqueue;         use BBqueue;
with BBqueue.Buffers; use BBqueue.Buffers;

with Pico_Keys.MIDI.Input;

package body Pico_Keys.MIDI.Serial is

   UART           : RP.UART.UART_Port renames RP.Device.UART_0;
   DMA_TX_Trigger : constant RP.DMA.DMA_Request_Trigger := RP.DMA.UART0_TX;
   UART_TX        : RP.GPIO.GPIO_Point := (Pin => 0);
   UART_RX        : RP.GPIO.GPIO_Point := (Pin => 1);

   Out_Grant : BBqueue.Buffers.Read_Grant;

   procedure UART0_RX_Handler;
   pragma Export (C, UART0_RX_Handler, "isr_irq20");

   ----------------------
   -- UART0_RX_Handler --
   ----------------------

   procedure UART0_RX_Handler is
   begin

      case UART.Receive_Status is

         when RP.UART.Not_Full | RP.UART.Full =>
            declare
               FIFO : UInt32 with Address => UART.FIFO_Address;
            begin
               MIDI.Input.Received (UInt8 (FIFO and 16#FF#));
            end;

         when RP.UART.Empty | RP.UART.Busy =>
            --  Impossible?
            null;

         when RP.UART.Invalid =>
            raise Program_Error;

      end case;


      --  UART0.Clear_IRQ (RP.UART.Receive);
   end UART0_RX_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      UART_TX.Configure (Output, Pull_Up, RP.GPIO.UART);

      UART_RX.Configure (Output, Floating, RP.GPIO.UART);

      UART.Configure
        (Config =>
           (Baud      => 31_250,
            Word_Size => 8,
            Parity    => False,
            Stop_Bits => 1,
            Enable_FIFOs => False,
            others    => <>));

      -- DMA --
      declare
         use RP.DMA;
         Config : DMA_Configuration;
      begin
         Config.Trigger := DMA_TX_Trigger;
         Config.High_Priority := True;
         Config.Data_Size := Transfer_8;
         Config.Increment_Read := True;
         Config.Increment_Write := False;

         RP.DMA.Configure (UART_TX_DMA, Config);
      end;

      UART.Enable_IRQ (RP.UART.Receive);
      UART.Set_FIFO_IRQ_Level (RX => RP.UART.Lvl_Eighth,
                               TX => RP.UART.Lvl_Eighth);
      Cortex_M.NVIC.Enable_Interrupt (RP2040_SVD.Interrupts.UART0_Interrupt);
   end Initialize;

   -----------
   -- Slush --
   -----------

   procedure Flush is
   begin
      if RP.DMA.Busy (UART_TX_DMA) then
         --  Previous DMA transfer still in progress
         return;
      end if;

      if State (Out_Grant) = Valid then
         --  Release the previous grant
         BBqueue.Buffers.Release (MIDI_Serial_Queue, Out_Grant);
      end if;

      --  Try to get a new grant
      BBqueue.Buffers.Read (MIDI_Serial_Queue, Out_Grant, BBqueue.Count'Last);

      if State (Out_Grant) = Valid then

         --  If we have a new grant, start DMA transfer

         RP.DMA.Start (Channel => UART_TX_DMA,
                       From    => Slice (Out_Grant).Addr,
                       To      => UART.FIFO_Address,
                       Count   => UInt32 (Slice (Out_Grant).Length));
      end if;

   end Flush;

begin
   Initialize;
end Pico_Keys.MIDI.Serial;
