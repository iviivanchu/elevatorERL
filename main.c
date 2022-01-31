#include <stdio.h>
#include <stdbool.h>
#include <avr/interrupt.h>
#include <avr/sfr_defs.h>
#include <avr/io.h>
#include <util/atomic.h>
#include <util/delay.h>
#include <pbn.h>

static void start(void);
static void led_on(void);
static void led_off(void);
static void display(void);

pin_t Pl0, Pl1, Pl2, Pl3, Pl4, Pl5; //LEDs de la planta.
pin_t D4, D5, D6, D7; //Display de 7 segments.
pin_t Bpl0, Bpl1, Bpl2, Bpl3, Bpl4, Bpl5; //Input del la botonera física.
pin_t Ap, Cp; //Input de obrir i tencar porta.

static void start(void) {

  Pl0 = pin_create(&PORTB, 5, Output);
  Pl1 = pin_create(&PORTB, 4, Output);
  Pl2 = pin_create(&PORTB, 3, Output);
  Pl3 = pin_create(&PORTB, 2, Output);
  Pl4 = pin_create(&PORTB, 1, Output);
  Pl5 = pin_create(&PORTB, 0, Output);

  D4 = pin_create(&PORTD, 4, Output);
  D5 = pin_create(&PORTD, 5, Output);
  D6 = pin_create(&PORTD, 6, Output);
  D7 = pin_create(&PORTD, 7, Output);

  Bpl0 = pin_create(&PORTC, 0, Input);
  Bpl1 = pin_create(&PORTC, 1, Input);
  Bpl2 = pin_create(&PORTC, 2, Input);
  Bpl3 = pin_create(&PORTC, 3, Input);
  Bpl4 = pin_create(&PORTC, 4, Input);
  Bpl5 = pin_create(&PORTC, 5, Input);

  Cp = pin_create(&PORTD, 2, Input);
  Ap = pin_create(&PORTD, 3, Input);

  PCMSK1 |= _BV(5) | _BV(4) | _BV(3) | _BV(2) | _BV(1) | _BV(0);
  PCMSK2 |= _BV(3) | _BV(2);
  PCIFR |= _BV(2) | _BV(1);
  PCICR |= _BV(2)|  _BV(1);
}

static void led_on(void) {

  uint8_t second;

  second = serial_get();
  switch (second) {
  case '0':
    pin_w(Pl0, true);
    break;
  case '1':
    pin_w(Pl1, true);
    break;
  case '2':
    pin_w(Pl2, true);
    break;
  case '3':
    pin_w(Pl3, true);
    break;
  case '4':
    pin_w(Pl4, true);
    break;
  case '5':
    pin_w(Pl5, true);
    break;
  }
}

static void led_off(void) {

  uint8_t second;

  second = serial_get();
  switch (second) {
  case '0':
    pin_w(Pl0, false);
    break;
  case '1':
    pin_w(Pl1, false);
    break;
  case '2':
    pin_w(Pl2, false);
    break;
  case '3':
    pin_w(Pl3, false);
    break;
  case '4':
    pin_w(Pl4, false);
    break;
  case '5':
    pin_w(Pl5, false);
    break;
  }
}

static void display(void) {

  uint8_t second;

  second = serial_get();
  switch (second) {
  case '0':
    pin_w(D4, false);
    pin_w(D5, false);
    pin_w(D6, false);
    pin_w(D7, false);
    break;
  case '1':
    pin_w(D4, true);
    pin_w(D5, false);
    pin_w(D6, false);
    pin_w(D7, false);
    break;
  case '2':
    pin_w(D4, false);
    pin_w(D5, false);
    pin_w(D6, false);
    pin_w(D7, true);
    break;
  case '3':
    pin_w(D4, true);
    pin_w(D5, false);
    pin_w(D6, false);
    pin_w(D7, true);
    break;
  case '4':
    pin_w(D4, false);
    pin_w(D5, false);
    pin_w(D6, true);
    pin_w(D7, false);
    break;
  case '5':
    pin_w(D4, true);
    pin_w(D5, false);
    pin_w(D6, true);
    pin_w(D7, false);
    break;
  }
}

ISR (PCINT1_vect) {

  ATOMIC_BLOCK (ATOMIC_RESTORESTATE) {
    if (!pin_r(Bpl0)) {
      serial_put('B');
      serial_put('0');
      serial_put('\n');
    }
    else if (!pin_r(Bpl1)) {
      serial_put('B');
      serial_put('1');
      serial_put('\n');
    }
    else if (!pin_r(Bpl2)) {
      serial_put('B');
      serial_put('2');
      serial_put('\n');
    }
    else if (!pin_r(Bpl3)) {
      serial_put('B');
      serial_put('3');
      serial_put('\n');
    }
    else if (!pin_r(Bpl4)){
      serial_put('B');
      serial_put('4');
      serial_put('\n');
    }
    else if (!pin_r(Bpl5)) {
      serial_put('B');
      serial_put('5');
      serial_put('\n');
    }
    _delay_ms(150);
    PCIFR |= _BV(1);
  }
}

ISR (PCINT2_vect){

  ATOMIC_BLOCK (ATOMIC_RESTORESTATE) {
    if(!pin_r(Ap)) {
      serial_put('O');
      serial_put('P');
      serial_put('\n');
    }
    else if(!pin_r(Cp)) {
      serial_put('T');
      serial_put('P');
      serial_put('\n');
    }
    _delay_ms(150);
    PCIFR |= _BV(2);
  }
}

void main(void) {

  sei();
  start();
  serial_open();
  uint8_t first;
  
  while (1) {

    while (!serial_can_read());
    
    first = serial_get();
    if (first == 'A')
      led_off();
    else if (first == 'E') 
      led_on();
    else if (first == 'D')
      display();
  }
}
