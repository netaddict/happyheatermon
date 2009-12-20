/*
 * HappyHeaterMon
 * by Bjoern Knorr 2009
 * http://netaddict.de/wiki/mikrocontroller:happyheatermon
 */

// libs
#include <LiquidCrystal.h>
#include <Wire.h>
#include <SRF02.h>

// define pins
#define STATUSGREENLED 13
#define STATUSREDLED 12
#define LCDRS 7
#define LCDENABLE 6
#define LCDDATA4 5
#define LCDDATA5 4
#define LCDDATA6 3
#define LCDDATA7 2
#define LCDBACKLIGHT 8
#define BUTTONOK 10
#define BUTTONHORZ 0
#define BUTTONVERT 1

#define BUTTONDEBOUNCETIME 25
#define BUTTONPRESSEDTIME 250

#define LCDWIDTH 20
#define LCDHEIGHT 4

// init LCD
LiquidCrystal lcd(LCDRS, LCDENABLE, LCDDATA4, LCDDATA5, LCDDATA6, LCDDATA7);

// init SRF02 sensor
SRF02 sensor(0x70, SRF02_CENTIMETERS);

// default values - i should move this to eeprom
int pelletMin = 15;
int pelletMax = 500;

// globar vars
int sensorPellet;
int pelletBarUnits;
int buttonHorzState = 0;
int buttonOkState = 0;
int buttonVertState = 0;
unsigned long timer0 = 0;
unsigned long timer1 = 0;
int menu = 0;

//setup function
void setup() {
  // set pin modes
  pinMode(STATUSGREENLED,OUTPUT);
  pinMode(STATUSREDLED,OUTPUT);
  pinMode(LCDBACKLIGHT,OUTPUT);
  pinMode(BUTTONOK,INPUT);
  digitalWrite(BUTTONOK,HIGH);
  
  statusLED(1);

  // a 20x4 LCD
  lcd.begin(LCDWIDTH, LCDHEIGHT);

  // define my own LCD chars
  lcdDefineChars();

  // start SRF02
  Wire.begin();

  // backlight on
  digitalWrite(LCDBACKLIGHT,HIGH);

  // print welcome screen
  lcd.setCursor(3, 1);
  lcd.print("HappyHeaterMon");
  lcd.setCursor(4, 2);
  lcd.print("V0.01 Alpha");
  delay(2000);

  // calculate bar graphs
  calcBargraphs();
  
  lcd.clear();
  statusLED(3);
}

// main loop
void loop() {
  SRF02::update();
  getButtons();
   
  if (millis() > timer0) {
    //readSensors();
    timer0 = millis() + 50;
  }
}

// set status LED (0=off, 1=red, 2=yellow, 3=green)
void statusLED(int led) {
  if (led == 0) {
    digitalWrite(STATUSGREENLED,LOW);
    digitalWrite(STATUSREDLED,LOW);
  }
  if (led == 1) {
    digitalWrite(STATUSGREENLED,LOW);
    digitalWrite(STATUSREDLED,HIGH);
  }
  if (led == 2) {
    digitalWrite(STATUSGREENLED,HIGH);
    digitalWrite(STATUSREDLED,HIGH);
  }
  if (led == 3) {
    digitalWrite(STATUSGREENLED,HIGH);
    digitalWrite(STATUSREDLED,LOW);
  }
}

// get the button states
void getButtons() {
  // debounce
  if (millis() < timer1) {
    return;
  }
  
  // Read Buttons
  int buttonHorzTmp = analogRead(BUTTONHORZ);
  int buttonVertTmp = analogRead(BUTTONVERT);
  int buttonOkTmp = digitalRead(BUTTONOK);

  // Horizontal
  if (buttonHorzState != buttonHorzTmp) {
    buttonHorzState = buttonHorzTmp;
    timer1 = millis()+BUTTONDEBOUNCETIME;
  };
 
  // Vertical
  if (buttonVertState != buttonVertTmp) {
    buttonVertState = buttonVertTmp;
    timer1 = millis()+BUTTONDEBOUNCETIME;
    
    // Menu back
    if (buttonVertState < 100) {
      if (menu == 0) {
        menu = 6;
      }
      else {
        menu--;
      }
      timer1 = millis()+BUTTONPRESSEDTIME;
    }
    
    // Menu forward
    if (buttonVertState > 900) {
      if (menu == 6) {
        menu = 0;
      }
      else {
        menu++;
      }
      timer1 = millis()+BUTTONPRESSEDTIME;
    }
  };
  
  // OK
  if (buttonOkState != buttonOkTmp) {
    buttonOkState = buttonOkTmp;
    timer1 = millis()+BUTTONDEBOUNCETIME;
  };

}

// own LCD characters
void lcdDefineChars() {
  byte mycharBlock[8] = {
    B11111,
    B11111,
    B11111,
    B11111,
    B11111,
    B11111,
    B11111,
  };
  lcd.createChar(0, mycharBlock);

  byte mycharSmile[8] = {
    B00000,
    B00000,
    B01010,
    B00000,
    B10001,
    B01110,
    B00000,
  };
  lcd.createChar(1, mycharSmile);

  byte mycharFrown[8] = {
    B00000,
    B00000,
    B01010,
    B00000,
    B01110,
    B10001,
    B00000,
  };
  lcd.createChar(2, mycharFrown);

  byte mycharTabLeft[8] = {
    B00011,
    B01111,
    B11111,
    B11111,
    B11111,
    B11111,
    B11111,
  };
  lcd.createChar(3, mycharTabLeft);
  
    byte mycharTabRight[8] = {
    B11000,
    B11110,
    B11111,
    B11111,
    B11111,
    B11111,
    B11111,
  };
  lcd.createChar(4, mycharTabRight);
}

// draw the status page
void drawStatus() {
  drawMenu(menu, "Status");
  lcd.setCursor(0, 1);
  lcd.print("Puffer");
  lcd.setCursor(0, 2);
  lcd.print("Pellet");
  lcd.setCursor(0, 3);
  lcd.print("Ofen");
  lcd.setCursor(9, 1); 
  lcd.print("|");
  lcd.setCursor(9, 2); 
  lcd.print("|");
  lcd.setCursor(9, 3); 
  lcd.print("|");
  lcd.setCursor(10, 1); 
  lcd.print("Solar");
  lcd.setCursor(10, 2); 
  lcd.print("Heizung");
  lcd.setCursor(10,3);
  lcd.print(" ");
  lcd.print("   ");
}

// draw the heater page

// draw the solar circuit page

// draw the radiator circuit page

// draw the pellet page
void drawPellets() {
  lcd.setCursor(0, 0);
  lcd.print("Pelletvorrat im Ofen");
  lcd.setCursor(0, 1);
  lcd.print("[              ]   %");
  lcd.setCursor(16, 1);
  lcd.print(((10000/(pelletMax - pelletMin))*sensorPellet)/100);
  sensorPellet = sensorPellet/pelletBarUnits;
  for (int i=1; i <= sensorPellet; i++){
    lcd.setCursor(i, 1);
    lcd.write(0);
  }
}

// draw credits page
void printCredits() {
  lcd.clear();
  lcd.setCursor(2, 1);
  lcd.print("by Bjoern Knorr");
  lcd.setCursor(0, 2);
  lcd.print("http://netaddict.de/");
  delay(4000);
  lcd.clear();
}

// draw menu bar
void drawMenu(int menu, char title[6]) {
  lcd.setCursor(0, 0);
  for (int i=0; i<7; i++) {
    lcd.write(3);
    if (i == menu) {
      lcd.print(title);
    }
    lcd.write(4);
  }
}

// read in all sesors and store the values into the variables
void readSensors(){
  statusLED(2);
  sensorPellet = sensor.read();
  statusLED(3);
}

// calculate bar graphs
void calcBargraphs() {
  pelletBarUnits = (pelletMax - pelletMin) / 14;
}

