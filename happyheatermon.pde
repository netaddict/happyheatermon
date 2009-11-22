/*
 * HappyHeaterMon
 * by Bjoern Knorr 2009
 * http://netaddict.de/wiki/mikrocontroller:happyheatermon
 * include the librarys
 */

// libs
#include <LiquidCrystal.h>
#include <Wire.h>
#include <SRF02.h>

// define section
#define STATUSGREENLED 13
#define STATUSREDLED 12
#define LCDBACKLIGHT 8

// init LCD (RS, Enable, D4, D5, D6, D7)
LiquidCrystal lcd(7, 6, 5, 4, 3, 2);

// init SRF02 sensor
SRF02 sensor(0x70, SRF02_CENTIMETERS);

// default values - i should move this to eeprom
int pelletMin = 15;
int pelletMax = 500;

// globar vars
int sensorPellet;
int pelletBarUnits;
unsigned long nextStart = 0;

//setup function
void setup() {
  // set pin modes
  pinMode(STATUSGREENLED,OUTPUT);
  pinMode(STATUSREDLED,OUTPUT);
  pinMode(LCDBACKLIGHT,OUTPUT);
  
  statusLED(1);
  
  // define my own LCD chars
  lcdDefineChars();

  // a 20x4 LCD
  lcd.begin(20, 4);

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
  if (millis() > nextStart) {
    readSensors();
    drawPellets();
    nextStart = millis () + 1000;
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

  byte mycharRight[8] = {
    B01000,
    B01100,
    B11110,
    B11111,
    B11110,
    B01100,
    B01000,
  };
  lcd.createChar(1, mycharRight);
}

// read in all sesors and store the values into the variables
void readSensors(){
  sensorPellet = sensor.read();
}

// draw the main page

// draw the heater page

// draw the solar circuit page

// draw the radiator circuit page

// draw the pellet page
void drawPellets() {
  lcd.setCursor(2, 3);
  lcd.print(sensorPellet);
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

// calculate bar graphs
void calcBargraphs() {
  pelletBarUnits = (pelletMax - pelletMin) / 14;
}

