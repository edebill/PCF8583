/*
  Implements a simple interface to the time function of the PCF8583 RTC chip

  Works around the device's limited year storage by keeping the year in the
  first two bytes of user accessible storage

  Assumes device is attached in the standard location - Analog pins 4 and 5
  Device address is the 8 bit address (as in the device datasheet - normally A0)

  Copyright (c) 2009, Erik DeBill


  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; either
  version 2.1 of the License, or (at your option) any later version.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/


#include <WProgram.h>
#include <../Wire/Wire.h>
#include "PCF8583.h"

PCF8583::PCF8583(int device_address) {
  address = device_address;
  Wire.begin();
}

void PCF8583::get_time(){
  Wire.beginTransmission(address);
  Wire.send(0xC0);   // stop counting, don't mask
  Wire.endTransmission();

  Wire.beginTransmission(address);
  Wire.send(0x02);
  Wire.endTransmission();
  Wire.requestFrom(address, 5);

  second = bcd_to_byte(Wire.receive());
  minute = bcd_to_byte(Wire.receive());
  hour   = bcd_to_byte(Wire.receive());
  byte incoming = Wire.receive(); // year/date counter
  day    = bcd_to_byte(incoming & 0x3f);
  year   = (int)((incoming >> 6) & 0x03);      // it will only hold 4 years...
  month  = bcd_to_byte(Wire.receive() & 0x1f);  // 0 out the weekdays part

  //  but that's not all - we need to find out what the base year is
  //  so we can add the 2 bits we got above and find the real year
  Wire.beginTransmission(address);
  Wire.send(0x10);
  Wire.endTransmission();
  Wire.requestFrom(address, 2);
  year_base = 0;
  year_base = Wire.receive();
  year_base = year_base << 8;
  year_base = year_base | Wire.receive();
  year = year + year_base;
}


void PCF8583::set_time(){
  Wire.beginTransmission(address);
  Wire.send(0xC0);   // stop counting, don't mask
  Wire.endTransmission();

  Wire.beginTransmission(address);
  Wire.send(0x02);
  Wire.send(int_to_bcd(second));
  Wire.send(int_to_bcd(minute));
  Wire.send(int_to_bcd(hour));
  Wire.send(((byte)(year % 4) << 6) | int_to_bcd(day));
  Wire.send(int_to_bcd(month));
  Wire.endTransmission();

  Wire.beginTransmission(address);
  Wire.send(0x10);
  year_base = year - year % 4;
  Wire.send(year_base >> 8);
  Wire.send(year_base & 0x00ff);
  Wire.endTransmission();
}


int PCF8583::bcd_to_byte(byte bcd){
  return ((bcd >> 4) * 10) + (bcd & 0x0f);
}

byte PCF8583::int_to_bcd(int in){
  return ((in / 10) << 4) + (in % 10);
}

