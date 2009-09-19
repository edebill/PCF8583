#include <Wire.h>
#include <stdio.h>
#include <PCF8583.h>
/*****************************************************************************
 *  read/write serial interface to PCF8583 RTC via I2C interface
 *
 *  Arduino analog input 5 - I2C SCL
 *  Arduino analog input 4 - I2C SDA
 *
 ******************************************************************************/
//  I2C device address is 0 1 0 0   A2 A1 A0
#define PCF8583_ADDRESS  ( 0xA0 >> 1)


int correct_address = 0;
PCF8583 p (PCF8583_ADDRESS);	
void setup(void){
  Serial.begin(9600);
  Serial.print("booting...");
  Serial.println(" done");

}



void loop(void){
  if(Serial.available() > 0){
       p.year= (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48)) + 2000;
       p.month = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
       p.day = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
       p.hour  = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
       p.minute = (byte) ((Serial.read() - 48) *10 +  (Serial.read() - 48));
       p.second = (byte) ((Serial.read() - 48) * 10 + (Serial.read() - 48)); // Use of (byte) type casting and ascii math to achieve result.  

       if(Serial.read() == ';'){
         Serial.println("setting date");
	 p.set_time();
       }
  }


  p.get_time();
  char time[50];
  sprintf(time, "%02d/%02d/%02d %02d:%02d:%02d",
	  p.year, p.month, p.day, p.hour, p.minute, p.second);
  Serial.println(time);

  delay(3000);
}





