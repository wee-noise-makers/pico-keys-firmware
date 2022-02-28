with RP.PWM; use RP.PWM;
with RP.GPIO; use RP.GPIO;
with RP.DMA;

with HAL; use HAL;

with Ada.Unchecked_Conversion;

package body Pico_Keys.Audio is

   BITS_PER_SAMPLE        : constant := 10;
   SAMPLE_BITS_TO_DISCARD : constant := (16 - BITS_PER_SAMPLE);
   PWM_TOP                : constant := (2**BITS_PER_SAMPLE) - 1;

   Pin   : GPIO_Point := (Pin => 9);
   Point : constant PWM_Point := To_PWM (Pin);

   DMA_IRQ : constant := 0;

   Audio_Buffer_Len : constant := 2**10;
   No_Data_Audio_Buffer : UInt16_Array (1 .. Audio_Buffer_Len);

   User_Handler : Audio_Handler := null
     with Atomic;

   procedure DMA_IRQ0_Handler
     with Export,
     Convention => C,
     External_Name => "isr_irq11";

   ----------------------
   -- DMA_IRQ0_Handler --
   ----------------------

   procedure DMA_IRQ0_Handler is
      use type System.Address;

      Buffer       : System.Address := System.Null_Address;
      Sample_Count : UInt32 := 0;
      Handler      : constant Audio_Handler := User_Handler;
   begin
      RP.DMA.Ack_IRQ (AUDIO_PWM_DMA, DMA_IRQ);

      if Handler /= null then
         Handler (Buffer, Sample_Count);
      end if;

      --  If we don't have a user handler, or the user handler didn't provide a
      --  buffer.
      if Buffer = System.Null_Address then
         --  Use empty data
         Buffer := No_Data_Audio_Buffer'Address;
         Sample_Count := No_Data_Audio_Buffer'Length;


      --  else
      --
      --     --  Convert Signed 16bit sample to UInt16 10 bits per sample
      --     declare
      --        Out_Data : array (1 .. Sample_Count) of UInt16
      --          with Address => Buffer;
      --     begin
      --        for Elt of Out_Data loop
      --           Elt := Shift_Right (Elt + 16#8000#, SAMPLE_BITS_TO_DISCARD);
      --        end loop;
      --     end;
      end if;

      RP.DMA.Start (Channel => AUDIO_PWM_DMA,
                    From    => Buffer,
                    To      => Compare_Reg_Address (Point),
                    Count   => Sample_Count);
   end DMA_IRQ0_Handler;

   -----------------
   -- Set_Handler --
   -----------------

   procedure Set_Handler (Handler : Audio_Handler) is
   begin
      User_Handler := Handler;
   end Set_Handler;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
   begin
      RP.PWM.Initialize;

      Pin.Configure (Output, Floating, PWM);

      --  Set_Frequency (Point.Slice, RP.Clock.Frequency (RP.Clock.SYS));
      Set_Divider (Point.Slice, 1.0);
      Set_Interval (Point.Slice, PWM_TOP);
      Set_Duty_Cycle (Point.Slice, Point.Channel, PWM_TOP / 2);

      --  Attach (Point.Slice, Int_Handler'Access);

      Enable (Point.Slice);

      --  $ python3
      --  >>> import fractions
      --  >>> fractions.Fraction(44100/120000000).limit_denominator(0xffff)
      --  Fraction(23, 62585)
      RP.DMA.Set_Pacing_Timer (Timer => RP.DMA.TIMER0,
                               X     => 23,
                               Y     => 62585);
      declare
         use RP.DMA;
         Config : DMA_Configuration;
      begin
         Config.Trigger := TIMER0;
         Config.Data_Size := Transfer_16;
         Config.Increment_Read := True;
         Config.Increment_Write := False;

         RP.DMA.Configure (AUDIO_PWM_DMA, Config);
         RP.DMA.Enable_IRQ (AUDIO_PWM_DMA, DMA_IRQ);
      end;

      --  Start the DMA cycle
      DMA_IRQ0_Handler;
   end Initialize;

begin
   Initialize;
end Pico_Keys.Audio;
