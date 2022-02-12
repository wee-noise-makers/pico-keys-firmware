with HAL; use HAL;

with RP.Device;
with RP.UART;
with RP.GPIO; use RP.GPIO;

with BBqueue;         use BBqueue;
with BBqueue.Buffers; use BBqueue.Buffers;

package body Pico_Keys.MIDI.Serial is

   UART           : RP.UART.UART_Port renames RP.Device.UART_0;
   DMA_TX_Trigger : constant RP.DMA.DMA_Request_Trigger := RP.DMA.UART0_TX;
   UART_TX        : RP.GPIO.GPIO_Point := (Pin => 0);

   Out_Grant : BBqueue.Buffers.Read_Grant;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      UART_TX.Configure (Output, Pull_Up, RP.GPIO.UART);
      UART.Configure
        (Config =>
           (Baud      => 31_250,
            Word_Size => 8,
            Parity    => False,
            Stop_Bits => 1,
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
