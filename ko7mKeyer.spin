con
{{
┌──────────────────────────────────────────┐
│ Morse Code Keyer/Transmitter-Version 1.4 │
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

  Revision History
  ----------------
  Rev 1.1 - Thanks to Eldon, WA0UWH for pointing out a logic flaw in my sendData method
  Rev 1.2 - Updated to make into a proper object.  Implemented get/put methods.
  Rev 1.3 - Implemented Iambic A and Iambic B modes and one element memory.  Made Iambic B mode default
  Rev 1.4 - Added bug mode (dits are automatic, dahs are not)
            Added straight key mode (dit key input keys manually)
            Added initPins(dit, dah, key, rf) to allow setting of pin assignments.  Defaults to 0, 1, 2, 27
            Added public method swapPaddles to allow switching dit and dah paddles   
}}

  _CLKMODE = XTAL1 + PLL16X
  _XINFREQ = 5_000_000

  WMin        =       381       ' WAITCNT-expression-overhead Minimum

  NL = 13                       ' Newline character
  SP = 32                       ' Space character

  USB = 1                       ' Upper sideband
  LSB = -1                      ' Lower sideband

  defaultFreq = 10_138_700      ' Output frequency initial value
  
  defaultErrorOffset =  20     ' Calibration value for particular propeller chip to zero beat Frequency
    
  defaultDitPin   =      0      ' Wired to dit paddle, grounded when pressed
  defaultDahPin   =      1      ' Wired to dah paddle, grounded when pressed
  defaultKeyPin   =      2      ' Output to transmitter keying circuit

  defaultRFPin    =     27      ' Synthesizer output pin - either at transmit freq or sidetone freq
  
  wpmInit  =            20      ' Initial code speed in words per minute

  #0, portA, portB              ' Port A is the only one that exists on P8X32A propeller chips
  #0, keyerModeA, keyerModeB, keyerModeBug, keyerModeStraight
  #0, activeHigh, activeLow     ' Whether output pin to key transmitter is active high or low
  #0, sendingNothing, sendingDit, sendingDah             ' 
  
var
  long ditBuffer                ' dit buffer
  long dahBuffer    '           ' dah buffer
  long Frequency                ' Current frequency
  long toneFreq                 ' Offset from frequency in Hz
  long ErrorOffset              ' Error calibration value
  long cogMain                  ' Cog for main (if run via start method)
  long cogMainStack[48]         ' Stack space for main cog                    
  long WPM                      ' Current keyer words per minute speed setting.
  long endTime                  ' delay counter end time
  byte CPM                      ' Current keyer characters per minute speed setting.
  byte keyerMode
  byte ditTime                  ' Time in milliseconds for a dit (dot)
  byte sideband                 ' Which sideband to use

  byte keyFlags                 ' Active high or active low keying of external transmitter
  byte beingSent                ' element currently being sent

  byte ditPin                   ' pin assignments
  byte dahPin
  byte keyPin
  byte RFPin
  
obj
  Freq : "Synth"

pub main
  run(defaultDitPin, defaultDahPin, defaultKeyPin, defaultRFPin)

pub run(dit, dah, key, rf)
  initPins(dit, dah, key, rf)
  doInitialize 
  repeat                        ' loop forever
    checkPaddles
    sendBuffer
    ditTime := 1200 / WPM

pub start(dit, dah, key, rf)
  stop
  return (cogMain := cognew(run(dit, dah, key, rf), @cogMainStack) + 1)

pub stop
  if cogMain
    cogstop(cogMain~ - 1)

pub getFreq
  return Frequency              ' Return current frequency

pub putFreq(_Freq)
  Frequency := _Freq            ' Set current frequency

pub getToneFreq
  return toneFreq               ' Set offset on transmit.  Defaults to 600 Hz

pub putToneFreq(_toneFreq)
  if _toneFreq >= -3000 and _toneFreq <= 3000
    toneFreq := _toneFreq       ' limit to +- 3K bandwidth

pub getErrorOffset
  return ErrorOffset            ' Get current propeller error calibration offset

pub putErrorOffset(_errorOffset)
  ErrorOffset := _errorOffset   ' Set propeller error calibration offset
  
pub getWPM
  return WPM                    ' Get current keyer words per minute                        

pub putWPM(_WPM)
  WPM := _WPM
  ditTime :=  1200 / WPM      ' Calculate dit time based on 50 dit duration standard
 
pub getKeyerMode
  return keyerMode              ' Get Iambic A or Iambic B mode - only Iambic A supported currently

pub putKeyerMode(_keyerMode)
  case keyerMode
    keyerModeA..keyerModeStraight:
      keyerMode := _keyerMode     ' set keyer mode

pub getSideband
  return sideband               ' Get current sideband to use USB / LSB

pub putSideBand(_sideBand)
  if _sideBand == USB or _sideBand == LSB
    sideband := _sideBand       ' Set current sideband

pub initPins(dit, dah, key, rf)
  ditPin := dit                 ' set up desired pin assignments
  dahPin := dah
  keyPin := key
  RFPin  := rf

pub swapPaddles
  ditPin ^= dahPin              ' swap dit and dah pin assignments
  dahPin := ditPin ^ dahPin
  ditPin ^= dahPin
                
pri doInitialize
  initPorts                     ' Initialize ports  
  WPM := wpmInit                ' Initial code speed
  CPM := 0                      ' Not currently used
  sideband := USB               ' Sideband defaults to USB
  Frequency := defaultFreq      ' Set initial frequency
  toneFreq  := 600 * sideband   ' Initial offset
  ErrorOffset := defaultErrorOffset  ' Propeller calibration error offset                                                          '                        
  keyerMode := keyerModeB       ' Default to mode B
  ditTime :=  1200 / WPM        ' Calculate dit time based on 50 dit duration standard
  keyFlags := activeHigh        ' Default to active high


pri initPorts
  DIRA[ditPin]~                 ' Paddle pins set to input
  DIRA[dahPin]~
  DIRA[keyPin]~~                ' Key and sidetone pins are output
  OUTA[keyPin]~~                ' Set key pin high
  
pri checkPaddles
  checkDitPaddle                ' check both paddles
  checkDahPaddle

pri checkDitPaddle
  if not ina[ditPin]            ' check ditPin for key down
    ditBuffer := 1

pri checkDahPaddle
  if not ina[dahPin]            ' check dahPin for key down
    dahBuffer := 1

pri sendBuffer
  case keyerMode
    keyerModeBug:               ' Bug mode
      if ditBuffer
        ditBuffer := 0
        sendDit
      if dahBuffer
        dahBuffer := 0
        keyDown
      else
        keyUp
    keyerModeStraight:          ' Straight key mode
      if ditBuffer
        ditBuffer := 0
        keyDown
      else
        keyUp
    other:                      ' Iambic A or B
      if ditBuffer
        ditBuffer := 0
        sendDit
      if dahBuffer
        dahBuffer := 0
        sendDah

pri sendDit
  beingSent := sendingDit
  keyDown
  delayAndWatchKey(ditTime)     ' wait 1 dit time while checking paddles
  keyUp
  if keyerMode == keyerModeA
    ditBuffer := dahBuffer := 0 ' don't complete next element in Iambic A
  delayAndWatchKey(ditTime)
  beingSent := sendingNothing

pri sendDah
  beingSent := sendingDah
  keyDown
  delayAndWatchKey(3 * ditTime) ' wait 3 dit times while checking paddles
  keyUp
  if keyerMode == keyerModeA
    ditBuffer := dahBuffer := 0 ' don't complete next element in Iambic A
  delayAndWatchKey(ditTime)
  beingSent := sendingNothing
  
pri delayAndWatchKey(duration)
  if duration > 0               ' duration is in milliseconds
    endTime := ((clkfreq / 1_000 * duration - 3932) #> WMin) + cnt ' calculate time to wait
    repeat while cnt < endTime
      case beingSent
        sendingDit: checkDahPaddle  ' check opposite paddle than element being sent
        sendingDah: checkDitPaddle
                                
pri sendTone(tone)
  Freq.Synth("A",RFPin, Frequency + tone + ErrorOffset)

pri noTone
  Freq.Synth("A",RFPin, 0)

pri keyDown
  case keyFlags
    activeLow:  OUTA[keypin]~   ' Set key output low
    activeHigh: OUTA[keypin]~~  ' Set key output high
  sendTone(toneFreq)            ' Sidetone or transmit

pri keyUp
  case keyFlags
    activeLow:  OUTA[keypin]~~  ' Set key output high
    activeHigh: OUTA[keypin]~   ' Set key output low
  noTone                        ' Stop sidetone or transmit
     
dat
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