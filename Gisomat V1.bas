'  -------------------------------------------------------------
'        Gisomat
'  - Selbsthaltung
'  - Abschalten bei Inaktivität

'  -------------------------------------------------------------

$Regfile="m8def.dat"
$Crystal=8000000
$hwstack=40
$swstack=16
$framesize=32
$baud  = 19200

const Timerkonstante=131    ' für INT in 1ms Raster
const SchaltSchwelleEin = 500
const SchaltSchwelleAus = 800
Const Autoabschaltung = 60                                  'Dauer, nach der bei keiner registrierten Änderung abgeschaltet wird
Const Hysteresedauer = 3


' Zisterne 470     ' stark abhängig von der verwendeten Elektrode
' Trinkwasser 340

' ------------------------------- Port -----------------------------------------
config portc.0=output: B_HLD alias portc.0:set b_hld       ' Power hold aktivieren
config portd.2=output:HSS alias portd.2:reset HSS
config portc.2=output:LED1 alias portc.2:set LED1
config portc.3=output:LED2 alias portc.3:set LED2

  ' config portb.6=output:LED_PWR alias portb.6:reset led_pwr  ' LED an


' ------------------------------- Initialisierung ------------------------------
' ADC
Config Adc = Single , Prescaler = Auto , Reference = avcc
Start Adc

Config Timer0 = Timer , Prescale = 64
On Ovf0 Tim0_isr
Tcnt0 = Timerkonstante

' ------------------------------- Variablendeklaration -------------------------
dim Batterie as word
dim Sensor as integer
dim prevSensor as integer
dim iDummy as integer

dim SekundenTicker as Integer
dim msTicker as integer
Dim Myflag As Byte
Flaghysterese Alias Myflag.0
Flagbatteriekritisch   Alias Myflag.1


   ' --------------------- Hauptprogramm ------------------------------------------


enable interrupts
enable timer0

reset LED1 ' LED an


do
   prevSensor=Sensor 'alter Wert speicher
   Sensor=getadc(6)
   Batterie = Getadc(7)
   waitms 300
   Print Sensor ; " " ; Sekundenticker ; "  Batterie: ";Batterie
   iDummy = prevSensor-Sensor:iDummy=abs(iDummy)

   If Idummy > 50 Then                                      'es hat sich was geändert
      Sekundenticker = 0
   end if

   If Sekundenticker => Hysteresedauer Then                  ' nur wiedereinschalten, nachdem gewisse Zeit gewartet wurde
      Flaghysterese = 0
   End If

   if Sensor < SchaltSchwelleEin then 'abschalten
      Reset Hss
      Set Led2
      Flaghysterese = 1
   Elseif Sensor > Schaltschwelleaus And Flaghysterese = 0 Then       'zuschaltne
      Set Hss
      Reset Led2
   end if

   'automatisch Ausschalten
   If Sekundenticker > Autoabschaltung Then
      Reset Hss
      Reset B_hld
   End If

   ' Sobald Batterie unter 6.5 V geht, wird dies mit LED angezeigt
   If Batterie < 360 Then                                   ' 360~ 6.4V  470~8.4V
      Flagbatteriekritisch = 1
   Elseif Batterie > 400 Then
      Flagbatteriekritisch = 0
      Reset Led1                                            ' PowerLED an
   End If

   Idummy = Sekundenticker Mod 2
   If Flagbatteriekritisch = 1 And Idummy = 0 Then Toggle Led1



loop




end


Tim0_isr:     ' ms Ticker
   incr  msTicker
   if msTicker>999 then
      incr SekundenTicker
      msTicker=0
   end if

   Tcnt0 = Timerkonstante
return