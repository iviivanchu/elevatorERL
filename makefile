CC = avr-gcc
CFLAGS = -std=c99 -Os -mmcu=atmega328p -fshort-enums -DF_CPU=16000000UL -Ilibpbn
LDFLAGS = -Os -mmcu=atmega328p
INYECTA = avrdude -c arduino -p atmega328p -P
AVR_OC = avr-objcopy -Oihex
DEVICE = /dev/ttyACM0
MODUL = CRC API lan frame

vpath lib% libpbn

.PHONY: carrega_ clean veryclean picocom

carrega_%: %.hex
	$(INYECTA) $(DEVICE) -U $<

%.hex: %
	$(AVR_OC) $< $@

picocom:
	picocom $(DEVICE)

clean:
	\rm -f *.c~ *.h~ *.makefile~

veryclean: clean
	\rm -f *.o *.hex $(MODUL)

main.o: main.c
main: main.o -lpbn



