# prototype CircuitPython firmware

import time
import board
import busio
import usb_midi
import digitalio

import adafruit_midi
from adafruit_midi.note_off import NoteOff
from adafruit_midi.note_on import NoteOn

import neopixel

# Definition of buttons (can I have enums please?)
btn_C    = 0
btn_Cs   = 1
btn_D    = 2
btn_Ds   = 3
btn_E    = 4
btn_F    = 5
btn_Fs   = 6
btn_G    = 7
btn_Gs   = 8
btn_A    = 9
btn_As   = 10
btn_B    = 11
btn_C2   = 12
btn_Cs2  = 13
btn_D2   = 14
btn_Ds2  = 15
btn_E2   = 16
btn_func = 17

# Aliases for func mode
btn_oct_minus = btn_Cs
btn_oct_plus = btn_Ds
btn_chan_minus = btn_Cs2
btn_chan_plus = btn_Ds2

# The GPIO coresponding to the given button
GP_for_button = {btn_C:    board.GP21,
                 btn_Cs:   board.GP22,
                 btn_D:    board.GP19,
                 btn_Ds:   board.GP20,
                 btn_E:    board.GP18,
                 btn_F:    board.GP16,
                 btn_Fs:   board.GP7,
                 btn_G:    board.GP17,
                 btn_Gs:   board.GP6,
                 btn_A:    board.GP15,
                 btn_As:   board.GP5,
                 btn_B:    board.GP14,
                 btn_C2:   board.GP13,
                 btn_Cs2:  board.GP4,
                 btn_D2:   board.GP12,
                 btn_Ds2:  board.GP3,
                 btn_E2:   board.GP8,
                 btn_func: board.GP2,
                }

# The LED index coresponding to the given button
LED_for_button = {btn_C:    8,
                  btn_Cs:   7,
                  btn_D:    9,
                  btn_Ds:   6,
                  btn_E:    10,
                  btn_F:    11,
                  btn_Fs:   5,
                  btn_G:    12,
                  btn_Gs:   4,
                  btn_A:    13,
                  btn_As:   3,
                  btn_B:    14,
                  btn_C2:   15,
                  btn_Cs2:  2,
                  btn_D2:   16,
                  btn_Ds2:  1,
                  btn_E2:   17,
                  btn_func: 0,
                }

# Init LEDs
num_pixels = 18
pixels = neopixel.NeoPixel(board.GP1, num_pixels)
pixels.brightness = 1.0

# Init USB midi`
midi_usb = adafruit_midi.MIDI(midi_out=usb_midi.ports[1], out_channel=0)

uart = busio.UART(board.GP0, rx=None, baudrate=31250, timeout=0.001)
midi_serial = adafruit_midi.MIDI(midi_out=uart, out_channel=0)


mode_key = 0
mode_seq = 1
mode_arp = 2

current_mode = mode_key

# Globals and init
root_note = 60
buttons = [None] * (btn_func + 1)
btn_state = [False] * (btn_func + 1)
btn_last_state = [False] * (btn_func + 1)
btn_note_on = [0] * (btn_func + 1)
for index in range(btn_func + 1):
    GP = GP_for_button[index]
    buttons[index] = digitalio.DigitalInOut(GP)
    buttons[index].switch_to_input(pull=digitalio.Pull.UP)

# Return True if the given button was just pressed
def falling(index):
    return btn_state[index] and not btn_last_state[index]

# Return True if the given button was just released
def raising(index):
    return not btn_state[index] and btn_last_state[index]

def note_on(note):
    midi_usb.send(NoteOn(note, 100))
    midi_serial.send(NoteOn(note, 100))

def note_off(note):
    midi_usb.send(NoteOff(note, 100))
    midi_serial.send(NoteOff(note, 100))

def midi_chan():
    return midi_usb.out_channel
    
def set_midi_chan(chan):
    midi_usb.out_channel = chan
    midi_serial.out_channel = chan

while True:
    
    # Get current state of buttons`
    for index in range(btn_func + 1):
        btn_last_state[index] = btn_state[index]
        btn_state[index] = not buttons[index].value

        if btn_state[index]:
            pixels[LED_for_button[index]] = (0, 255, 0)
        else:
            pixels[LED_for_button[index]] = (0, 0, 0)


    if btn_state[btn_func]:

        # Kill notes still on
        for index in range(btn_func + 1):
            if btn_note_on[index] != 0:
                note_off(btn_note_on[index])
                btn_note_on[index] = 0

        if falling(btn_oct_minus) and root_note > 24:
            root_note -= 12
        elif falling(btn_oct_plus) and root_note < 96:
            root_note += 12

        if falling(btn_chan_minus) and midi_chan() > 0:
            set_midi_chan (midi_chan() - 1)
        elif falling(btn_chan_plus) and midi_chan() < 15:
            set_midi_chan (midi_chan() + 1)
        
    else:
        if current_mode == mode_key:
            for index in range(btn_func):
                if falling(index):
                    note_on(root_note + index)
                    btn_note_on[index] = root_note + index
                if raising(index):
                    note_off(root_note + index)
                    btn_note_on[index] = 0
        elif current_mode == mode_arp:
            null
        elif current_mode == mode_seq:
            null

    pixels.show()


