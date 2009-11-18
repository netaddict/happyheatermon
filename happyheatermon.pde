/*
 * HappyHeaterMon
 * by Bjoern Knorr 2009
 * http://netaddict.de/wiki/mikrocontroller:happyheatermon
 * include the librarys
 */

#include <LiquidCrystal.h>
#include <Wire.h>
#include <SRF02.h>

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
  // define my own chars
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

  // a 20x4 lcd
  lcd.begin(20, 4);

  // backlight on
  delay(200);
  pinMode(8,OUTPUT);
  digitalWrite(8,HIGH);
  lcd.clear();
  delay(500);

  // print welcome screen
  lcd.setCursor(7,1);
  lcd.print("Hello");
  delay(1000);
  lcd.setCursor(4, 2);
  lcd.print("welcome to:");  
  delay(1500);
  lcd.setCursor(3, 1);
  lcd.print("HappyHeaterMon");
  lcd.setCursor(4, 2);
  lcd.print("V0.01 Alpha");
  delay(3000);
  lcd.clear();
  lcd.setCursor(2, 1);
  lcd.print("by Bjoern Knorr");
  lcd.setCursor(0, 2);
  lcd.print("http://netaddict.de/");
  delay(4000);
  lcd.clear();

  // start SRF02
  Wire.begin();

  // calculate bar graphs
  calcBargraphs();
}

void loop() {
  SRF02::update();
  if (millis() > nextStart) {
    readSensors();
    drawPellets();
    nextStart = millis () + 1000;
  }
}

// read in all sesors and store the values into the variables
void readSensors(){
  sensorPellet = sensor.read();
}

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

// calculate bar graphs
void calcBargraphs() {
  pelletBarUnits = (pelletMax - pelletMin) / 14;
}

