#include <Wire.h>
#include <stdio.h>

/*****************************************************************************
 *  read/write serial interface to PCF8583 RTC via I2C interface
 *
 *  Arduino analog input 5 - I2C SCL
 *  Arduino analog input 4 - I2C SDA
 *
 ******************************************************************************/
//  I2C device address is 0 1 0 0   A2 A1 A0
#define PCF8583_ADDRESS  ( 0xA0 >> 1)

class PCF8583 {
  int address;
public:
  int second;
  int minute;
  int hour;
  int day;
  int month;
  int year;
  int year_base;
  

  PCF8583(int a);
  void get_time();
  void set_time();

};

PCF8583::PCF8583(int a) {
  address = a;
}

int correct_address = 0;

void setup(void){
  Serial.begin(9600);
  Serial.print("booting...");
  Wire.begin();
  PCF8583 p (PCF8583_ADDRESS);
  p.day = 12;
  p.hour = 4;
  p.minute = 35;
  p.second = 0;
  p.month = 9;
  p.year = 2009;
  p.set_time();
  Serial.println(" done");
}


int x;
void loop(void){
  PCF8583 p (PCF8583_ADDRESS);
  p.year_base = 2008;
  p.get_time();
  char time[50];
  sprintf(time, "%02d/%02d/%02d %02d:%02d:%02d",
	  p.year + p.year_base, p.month, p.day, p.hour, p.minute, p.second);
  Serial.println(time);

  delay(3000);
}




int bcd_to_byte(byte bcd){
  return ((bcd >> 4) * 10) + (bcd & 0x0f);
}

byte int_to_bcd(int in){
  return ((in / 10) << 4) + (in % 10);
}



void PCF8583::get_time(){
  Serial.print("request from ");
  Serial.println(address);
  Wire.beginTransmission(address);
  Wire.send(0xC0);   // stop counting, mask day of week
  Wire.endTransmission();

  Wire.beginTransmission(address);
  Wire.send(0x02);
  Wire.endTransmission();
  Wire.requestFrom(address, 5);
  delay(50);
  second = bcd_to_byte(Wire.receive());
  minute = bcd_to_byte(Wire.receive());
  hour   = bcd_to_byte(Wire.receive());
  byte incoming = Wire.receive(); // year/date counter
  Serial.println((int)incoming);
  day    = bcd_to_byte(incoming & 0x3f);
  year   = (int)((incoming >> 6) & 0x03);      // it will only hold 4 years...
  month  = bcd_to_byte(Wire.receive() & 0x1f);  // 0 out the weekdays part
}


void PCF8583::set_time(){
  Wire.beginTransmission(address);
  Wire.send(0xC0);   // stop counting, mask day of week
  Wire.endTransmission();

  Wire.beginTransmission(address);
  Wire.send(0x02);
  Wire.send(int_to_bcd(second));
  Wire.send(int_to_bcd(minute));
  Wire.send(int_to_bcd(hour));
  Serial.print("setting day/year to ");
  Serial.println(((byte)(year % 4) << 6) | int_to_bcd(day));
  Wire.send(((byte)(year % 4) << 6) | int_to_bcd(day));
  Wire.send(int_to_bcd(month));
  Wire.endTransmission();

  year_base = year - year % 4;
  Serial.print("year_base = ");
  Serial.println(year_base);
}
