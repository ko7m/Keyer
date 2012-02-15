CON
{{
┌──────────────────────────────────────────┐
│ Morse Code Keyer/Transmitter-Version 1.0 │
│ Author: Jeff Whitlatch                   │               
│ Copyright (c) 2012 Jeff Whitlatch        │               
│ See end of file for terms of use.        │                
└──────────────────────────────────────────┘

  Iamb or Iambus - a metrical foot consisting of two syllables, a short one followed by a long one.
  
  With an Iambic paddle, one contact is present for the dits (left paddle) and another for dahs (right paddle).
  Each contact may be closed simultaneously.  The iambic function (alternating dits and dahs) are created
  by squeezing the paddles together.

  Iambic keyers function in at least two major modes.

  Mode A is the original iambic mode, in which alternate dits and dahs are produced as long as both paddles
  are depressed.  When the paddles are released, the keying stops with the last dit or dah that was sent
  while the paddles were depressed.

  Mode B devolved from a logic error in an early iambic keyer.  Dits and dahs are produced as long as both
  paddles are depressed.  When the paddles are released, the keying continues by sending one more element, i.e.,
  a dit if the paddles were released during a dah or a dah if the paddles were released during a dit.  Users
  accustomed to one mode usually have difficulty utilizing the other, so all competent keyer designs have the
  capability of selecting the desired keyer mode.  If forced to use a keyer with an unaccustomed mode, the user
  must revert to a single paddle mode in which both paddles are never depressed simultaneously.

  International Morse Code is composed of five elements.

  1. dit - duration is one unit long.
  2. dah - duration is three units long.
  3. inter-element gap between dit and dah elements within a character - duration is one unit long.
  4. gap between letters - duration is three units long.
  5. gap between words - duration is seven units long.

  Code speed is defined by two factors.

  1. Character speed - how fast each character is sent.
  2. Text speed - how fast the entire message is sent.

  The Farnsworth method of learning morse code sends individual characters at the highest speed to be accomplished
  in training but spaces out characters to send the overall text more slowly that each individual character.

  All Morse Code elements depend on dit length (also sometimes referred to as "dot length").  A dah is the length
  of 3 dits and spacings are specified in number of dit lengths.  Because of this, some method of to standardize
  the dit length is useful.  A simple way to do this is to send the same 5-character word over and over for one
  minute at a speed that will allow the operator to send the correct number of words in one minutes.  If for example
  the operator wanted to achieve 13 words per minute (WPM), the operator would send the 5-character word 13 times in
  precisely one minute.  From this the operator would arrive at a dit length necessary to produce 13 words per minute
  while meeting all the standards.

  The word one chooses determines the dit length.  A word with more dits like "PARIS" would be sent with longer
  dits to fill in one minute.  A word with more dahs like "CODEX" would produce a shorter dit length so everything
  woudl fit in one minute.  PARIS and CODEX are frequently used as Morse Code standard words.  Using the word PARIS
  as the standard, the number of dit units is 50 and a simple calculation shows that the dit length at 20 WPM is
  60 milliseconds.  Using the word CODEX with 60 dit units, the length at 20 WPM is 50 milliseconds.
   
  Using the 50 dit duration standard, the time for one dit duration or one unit is computed by:

  T = 1200 / W  or  T = 6000 / C where T = dit duration in ms, W is speed in WPM and C is speed in CPM

  This code can be used as a keyer to driver an external transmitter, or it can be used as a CW transmitter by
  merely changing the Frequency value from 0 to the desired transmit frequency.
  
}}

  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000

  WMin        =       381       ' WAITCNT-expression-overhead Minimum

  NL = 13                       ' Newline character
  SP = 32                       ' Space character

  USB = 1                       ' Upper sideband
  LSB = -1                      ' Lower sideband

  sideband    =        USB      ' Which sideband to use for offset
  Frequency   = 10_138_700      ' Output frequency zero
  toneFreq = 600 * sideband     ' 600 Hz offset for CW operation
  ErrorOffset =         20      ' Calibration value for particular propeller chip to zero bete Frequency
    
  ditPin   =             0      ' Wired to dit paddle, grounded when pressed
  dahPin   =             1      ' Wired to dah paddle, grounded when pressed
  keyPin   =             2      ' Output to transmitter keying circuit

  RFPin    =            27      ' Synthesizer output pin - either at transmit freq or sidetone freq
  
  wpmInit  =            20      ' Initial code speed in words per minute

  #0, portA, portB              ' Port A is the only one that exists on P8X32A propeller chips
  #0, keyerModeA, keyerModeB    ' Iambic mode A or B
  #0, lastWasDit, lastWasDah    ' Remembering if we sent a dit or dah last time
  #0, activeHigh, activeLow     ' Whether output pin to key transmitter is active high or low             ' 
  
VAR
  LONG paddleMask               ' Mask for paddle bits in Port A
  LONG paddleData               ' Actual paddle data
  LONG portABits                ' Which paddles are currently down                        
  BYTE WPM                      ' Current keyer words per minute speed setting.
  BYTE CPM                      ' Current keyer characters per minute speed setting.
  BYTE keyerMode
  BYTE ditTime                  ' Time in milliseconds for a dit (dot)
  BYTE lastWas                  ' Last element sent was dit or dah
  BYTE keyFlags                 ' Active high or active low keying of external transmitter
  
OBJ
  Freq : "Synth"
  T    : "tv_terminal"

DAT
  szTitle byte 2, "30 Meter CW Transmitter", NL, NL, 0
  szMHz   byte " MHz - Offset ", 0
  szWPM   byte " WPM", NL, NL, 0
   
PUB main | cog, data
  doInitialize
  displayFreq
  displayWPM
  repeat                        ' Loop forever (for now)
    paddleData := doWaitForKey  ' Sleep unless one of the paddles is pressed
    repeat until paddleData == paddleMask
      sendData(paddleData)
      delayMS(ditTime)
      paddleData := ina & paddleMask
  
PRI doInitialize
  T.Start(12)                   ' Start up TV Terminal
  T.Str(@szTitle)
  DIRA[ditPin]~                 ' Paddle pins set to input
  DIRA[dahPin]~
  DIRA[keyPin]~~                ' Key and sidetone pins are output

  OUTA[keyPin]~~                ' Set key pin high                        
  
  paddleMask := (1 << ditPin) | (1 << dahPin)
  
  WPM := wpmInit                ' Initial code speed
  CPM := 0                      ' Not currently used                                     '                        
  keyerMode := keyerModeA       ' Default to mode A
  ditTime :=  1200 / WPM        ' Calculate dit time based on 50 dit duration standard
  keyFlags := activeHigh        ' Default to active high                     

PRI doWaitForKey
  waitpeq(paddleMask, paddleMask, portA)  ' Wait for no paddle pressed
  waitpne(paddleMask, paddleMask, portA)  ' Wait for either paddle to be pressed
  return ina & paddleMask                 ' Just grab the entire 32 bit register and mask off
  
PRI sendData(data)
  if not data                   ' Both paddles held
    case lastWas
      lastWasDit: sendDah       ' Swap dits and dahs until some paddle is released
      lastWasDah: sendDit       
  else                          
    if not paddleData & ditPin  ' Arbitrarily choose to check dit first
      sendDit                   ' Send a dit
    if not paddleData & dahPin  ' Now check for dah
      sendDah                   ' Send a dah
    
PRI sendDit
  keyDown
  delayMS(ditTime)              ' 1x ditTime for Dit
  keyUp
  lastWas := lastWasDit         ' Remember last element sent

PRI sendDah
  keyDown
  delayMS(3 * ditTime)          ' 3x ditTime for Dah
  keyUp
  lastWas := lastWasDah         ' Remember last element sent
                            
PRI sendTone(tone)
  Freq.Synth("A",RFPin, Frequency + tone + ErrorOffset)

PRI noTone
  Freq.Synth("A",RFPin, 0)

PRI keyDown
  case keyFlags
    activeLow:  OUTA[keypin]~   ' Set key output low
    activeHigh: OUTA[keypin]~~  ' Set key output high
  sendTone(toneFreq)            ' Sidetone or transmit

PRI keyUp
  case keyFlags
    activeLow:  OUTA[keypin]~~   ' Set key output high
    activeHigh: OUTA[keypin]~   ' Set key output low
  noTone                        ' Stop sidetone or transmit                        

PRI displayFreq | MHz, KHz, Hz
  MHz := Frequency / 1_000_000
  KHz := (Frequency - MHz * 1_000_000) / 1_000
  Hz := Frequency - MHz * 1_000_000 - KHz * 1_000
  T.Dec(MHz)
  T.Out(".")
  T.Dec(KHz)
  T.Out(".")
  T.Dec(Hz)
  T.Str(@szMHz)
  T.Dec(toneFreq)
  T.Out(NL)

PRI displayWPM
  T.Out(NL)
  T.Dec(WPM)
  T.Str(@szWPM)
           
PRI delayMS(Duration)
  waitcnt(((clkfreq / 1_000 * Duration - 3932) #> WMin) + cnt)

PRI delayUS(Duration)
  waitcnt(((clkfreq / 1_000_000 * Duration - 3932) #> WMin) + cnt)
     
DAT
{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}          