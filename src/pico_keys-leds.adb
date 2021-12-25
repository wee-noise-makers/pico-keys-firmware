with HAL; use HAL;

with RP.Device;
with RP.PIO; use RP.PIO;
with RP.GPIO; use RP.GPIO;
with RP.DMA;

with Pico_Keys.WS2812_PIO_ASM;
with Pico_Keys.PIO; use Pico_Keys.PIO;

package body Pico_Keys.LEDs is

   Out_Pin : RP.GPIO.GPIO_Point := (Pin => 1);

   Number_Of_LEDs : constant := 18;
   type LED_ID is range 1 .. Number_Of_LEDs;
   type LED_Data is array (LED_ID) of HAL.UInt32;
   type LED_Data_Access is access all LED_Data;

   Button_To_LED : constant array (Button_ID) of LED_ID :=
     (btn_C    => 9,
      btn_Cs   => 8,
      btn_D    => 10,
      btn_Ds   => 7,
      btn_E    => 11,
      btn_F    => 12,
      btn_Fs   => 6,
      btn_G    => 13,
      btn_Gs   => 5,
      btn_A    => 14,
      btn_As   => 4,
      btn_B    => 15,
      btn_C2   => 16,
      btn_C2s  => 3,
      btn_D2   => 17,
      btn_D2s  => 2,
      btn_E2   => 18,
      btn_func => 1
     );

   Data : aliased LED_Data := (others => 0);
   Step_Cnt : UInt32 := 0;

   procedure Push_Data_DMA (Data : not null LED_Data_Access);

   --------------
   -- Blink_On --
   --------------

   function Blink_On return Boolean is
   begin
      return (Step_Cnt mod 1_000) < 500;
   end Blink_On;

   -------------------
   -- Blink_Fast_On --
   -------------------

   function Blink_Fast_On return Boolean is
   begin
      return (Step_Cnt mod 100) < 50;
   end Blink_Fast_On;

   -----------
   -- Clear --
   -----------

   procedure Clear is
   begin
      Data := (others => 0);
   end Clear;

   ------------
   -- Update --
   ------------

   procedure Update is
   begin
      Step_Cnt := Step_Cnt + 1;
      Push_Data_DMA (Data'Access);
   end Update;

   -------------
   -- Set_RGB --
   -------------

   procedure Set_RGB (Id : Button_ID; R, G, B : HAL.UInt8) is
   begin
      Data (Button_To_LED (Id)) := Shift_Left (UInt32 (B), 16)
        or Shift_Left (UInt32 (R), 8)
        or Shift_Left (UInt32 (G), 0);
   end Set_RGB;

   -------------
   -- Set_HSV --
   -------------

   procedure Set_HSV (Id   : Button_ID;
                      H    : Hue;
                      S, V : HAL.UInt8)
   is
      R, G, B : UInt8;

      Region, Remainder : UInt32;
      P, Q, T : UInt8;
   begin
      if S = 0 then
         R := V;
         G := V;
         B := V;
      else

         Region := Uint32 (H / 43);
         Remainder := (Uint32 (H) - (Region * 43)) * 6;

         P := UInt8 (Shift_Right (Uint32 (V) * (255 - Uint32 (S)), 8));
         Q := UInt8 (Shift_Right (Uint32 (V) * (255 - Shift_Right (Uint32 (S) * Remainder, 8)), 8));
         T := UInt8 (Shift_Right (Uint32 (V) * (255 - Shift_Right (Uint32 (S) * (255 - Remainder), 8)), 8));

         case (Region) is
            when      0 => R := V; G := T; B := P;
            when      1 => R := Q; G := V; B := P;
            when      2 => R := P; G := V; B := T;
            when      3 => R := P; G := Q; B := V;
            when      4 => R := T; G := P; B := V;
            when others => R := V; G := P; B := Q;
         end case;
      end if;

      Set_RGB (Id, R, G, B);
   end Set_HSV;

   -------------
   -- Set_Hue --
   -------------

   procedure Set_Hue (Id : Button_ID; H : Hue; Effect : LED_Effect := None) is
   begin
      case Effect is
         when None =>
            Set_HSV (Id, H, UInt8'Last, UInt8'Last);
         when Blink =>
            if Blink_On then
               Set_HSV (Id, H, UInt8'Last, UInt8'Last);
            end if;
         when Blink_Fast =>
            if Blink_Fast_On then
               Set_HSV (Id, H, UInt8'Last, UInt8'Last);
            end if;
         when Dim =>
            Set_HSV (Id, H, UInt8'Last / 4, UInt8'Last);
      end case;
   end Set_Hue;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      Config         : PIO_SM_Config := Default_SM_Config;

      Freq           : constant := 80_0000;
      Cycles_Per_Bit : constant := WS2812_PIO_ASM.T1 +
        WS2812_PIO_ASM.T2 + WS2812_PIO_ASM.T3;

      Bit_Per_LED : constant := 24;

   begin
      Out_Pin.Configure (Output, Pull_Up, WS2812_PIO.GPIO_Function);

      WS2812_PIO.Enable;

      WS2812_PIO.Load (WS2812_PIO_ASM.Ws2812_Program_Instructions,
                       Offset => WS2812_Offset);

      WS2812_PIO.Set_Pin_Direction (WS2812_SM, Out_Pin.Pin, Output);

      Set_Sideset (Config,
                   Bit_Count => 1,
                   Optional  => False,
                   Pindirs   => False);
      Set_Sideset_Pins (Config, Sideset_Base => Out_Pin.Pin);

      Set_Out_Shift (Config,
                     Shift_Right    => True,
                     Autopull       => True,
                     Pull_Threshold => Bit_Per_LED);
      Set_FIFO_Join (Config,
                     Join_TX => True,
                     Join_RX => False);

      Set_Wrap (Config,
                WS2812_Offset + WS2812_PIO_ASM.Ws2812_Wrap_Target,
                WS2812_Offset + WS2812_PIO_ASM.Ws2812_Wrap);
      Set_Clock_Frequency (Config, Freq * Cycles_Per_Bit);

      WS2812_PIO.SM_Initialize (WS2812_SM,
                                WS2812_Offset,
                                Config);
      WS2812_PIO.Set_Enabled (WS2812_SM, True);

      -- DMA --
      declare
         use RP.DMA;
         Config : DMA_Configuration;
      begin
         Config.Trigger := WS2812_DMA_Trigger;
         Config.Data_Size := Transfer_32;
         Config.Increment_Read := True;
         Config.Increment_Write := False;

         RP.DMA.Configure (LED_PIO_DMA, Config);
      end;

   end Initialize;

   -------------------
   -- Push_Data_DMA --
   -------------------

   procedure Push_Data_DMA (Data : not null LED_Data_Access) is
   begin
      if RP.DMA.Busy (LED_PIO_DMA) then
         --  Previous DMA transfer still in progress
         return;
      end if;

      RP.DMA.Start (Channel => LED_PIO_DMA,
                    From    => Data.all'Address,
                    To      => WS2812_PIO.TX_FIFO_Address (WS2812_SM),
                    Count   => Data.all'Length);
   end Push_Data_DMA;

begin
   Initialize;
end Pico_Keys.LEDs;
