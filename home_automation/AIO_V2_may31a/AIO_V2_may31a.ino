#include "DHT.h"
#include <IRremote.h>   // https://github.com/Arduino-IRremote/Arduino-IRremote (3.6.1)
#include <AceButton.h>  // https://github.com/bxparks/AceButton (1.9.2)
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <SD.h>
#include <time.h>
#include <addons/TokenHelper.h>
#include <addons/RTDBHelper.h>  

// Replace these with your actual credentials
#define WIFI_SSID "Augustine"
#define WIFI_PASSWORD "qwertyui"

#define API_KEY "AIzaSyCgrkvY-A7KuzP7_534uegjodm4vyZkhAY"
#define DATABASE_URL "https://home-automation-78d43-default-rtdb.asia-southeast1.firebasedatabase.app/"
#define USER_EMAIL "a@gmail.com"
#define USER_PASSWORD "123456"

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

#define DHTPIN 16
#define DHTTYPE DHT11
#define irPin 17  // IR sensor pin

DHT dht(DHTPIN, DHTTYPE);

using namespace ace_button;

bool DEBUG_SW = 1;

unsigned long previousMillis = 0;  // Stores the last time data was sent
const long interval = 5000;        // Interval at which to send data (milliseconds)

// Pins of Fan Regulator Knob
#define fan_switch 33
#define s1 27
#define s2 14
#define s3 12
#define s4 13

// Pins of Switches
#define S5 32
#define S6 35
#define S7 34
#define S8 39

// Pins of Relay (Appliances Control)
#define R5 15
#define R6 2
#define R7 4
#define R8 22

// Pins of Relay (Fan Speed Control)
#define Speed1 21
#define Speed2 19
#define Speed4 18

bool speed1_flag = 1;
bool speed2_flag = 1;
bool speed3_flag = 1;
bool speed4_flag = 1;
bool speed0_flag = 1;

int switch_ON_Flag1_previous_I = 0;
int switch_ON_Flag2_previous_I = 0;
int switch_ON_Flag3_previous_I = 0;
int switch_ON_Flag4_previous_I = 0;

int curr_speed = 0;
bool fan_power = 0;

// IR Remote Code for Lights
#define IR_Relay1 0x1FE50AF
#define IR_Relay2 0x1FED827
#define IR_Relay3 0x1FEF807
#define IR_Relay4 0x1FE30CF
#define IR_Relay_All_Off 0x1FE48B7
#define IR_Relay_All_On 0x1FE7887

// IR Remote Code for Fan
#define IR_Speed_Up 0x1FE609F
#define IR_Speed_Dw 0x1FEA05F
#define IR_Fan_off 0x1FE10EF
#define IR_Fan_on 0x1FE906F

IRrecv irrecv(irPin);
decode_results results;

ButtonConfig config1;
AceButton button1(&config1);
ButtonConfig config2;
AceButton button2(&config2);
ButtonConfig config3;
AceButton button3(&config3);
ButtonConfig config4;
AceButton button4(&config4);
ButtonConfig config5;
AceButton button5(&config5);

void handleEvent1(AceButton*, uint8_t, uint8_t);
void handleEvent2(AceButton*, uint8_t, uint8_t);
void handleEvent3(AceButton*, uint8_t, uint8_t);
void handleEvent4(AceButton*, uint8_t, uint8_t);
void handleEvent5(AceButton*, uint8_t, uint8_t);

// Add these global variables
bool relay1 = false, relay2 = false, relay3 = false, relay4 = false;
float temperature = 0, humidity = 0;

const char* ntpServer = "pool.ntp.org";
const long  gmtOffset_sec = 0;
const int   daylightOffset_sec = 3600;

bool testFirebaseConnection() {
  if (Firebase.setString(fbdo, "/test", "ESP32 is connected")) {
    Serial.println("Firebase test write successful");
    return true;
  } else {
    Serial.printf("Firebase test write failed: %s\n", fbdo.errorReason().c_str());
    return false;
  }
}

void setup() {
  Serial.begin(115200);
  Serial.println("\nInitializing...");

  // WiFi Connection
  Serial.printf("Connecting to WiFi SSID: %s\n", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  unsigned long wifiStartTime = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - wifiStartTime < 20000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(WiFi.status() == WL_CONNECTED ? "\nWiFi connected" : "\nWiFi connection failed");

  // Time synchronization
  Serial.println("Synchronizing time...");
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);
  unsigned long timeStartTime = millis();
  while (time(nullptr) < 1000000000 && millis() - timeStartTime < 10000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(time(nullptr) > 1000000000 ? "Time synchronized" : "Time synchronization failed");

  // Firebase setup
  Serial.printf("Initializing Firebase (Client v%s)...\n", FIREBASE_CLIENT_VERSION);
  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  auth.user.email = USER_EMAIL;
  auth.user.password = USER_PASSWORD;

  Serial.println("Signing up...");
  if (Firebase.signUp(&config, &auth, USER_EMAIL, USER_PASSWORD)) {
    Serial.println("Sign up successful");
    config.token_status_callback = tokenStatusCallback;
  } else {
    Serial.printf("Sign up failed: %s\n", config.signer.signupError.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);

  Serial.println("Connecting to Firebase...");
  unsigned long fbStartTime = millis();
  while (!Firebase.ready() && millis() - fbStartTime < 30000) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(Firebase.ready() ? "Firebase connected!" : "Failed to connect to Firebase after 30 seconds");

  dht.begin();
  irrecv.enableIRIn();  // Enabling IR sensor

  pinMode(s1, INPUT);
  pinMode(s2, INPUT);
  pinMode(s3, INPUT_PULLUP);
  pinMode(s4, INPUT);
  pinMode(S5, INPUT);
  pinMode(S6, INPUT);
  pinMode(S7, INPUT);
  pinMode(S8, INPUT);

  pinMode(R5, OUTPUT);
  pinMode(R6, OUTPUT);
  pinMode(R7, OUTPUT);
  pinMode(R8, OUTPUT);
  pinMode(Speed1, OUTPUT);
  pinMode(Speed2, OUTPUT);
  pinMode(Speed4, OUTPUT);

  config1.setEventHandler(button1Handler);
  config2.setEventHandler(button2Handler);
  config3.setEventHandler(button3Handler);
  config4.setEventHandler(button4Handler);
  config5.setEventHandler(button5Handler);

  button1.init(S5);
  button2.init(S6);
  button3.init(S7);
  button4.init(S8);
  button5.init(fan_switch);

  // This delay gives the chance to wait for a Serial Monitor without blocking if none is found
  delay(1500);

  Serial.println("Setup complete.");
}

void loop() {
  static unsigned long lastCheck = 0;
  unsigned long now = millis();

  // Check WiFi connection status
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("WiFi connection lost. Reconnecting...");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
      delay(500);
      Serial.print(".");
    }
    Serial.println();
    Serial.print("Reconnected with IP: ");
    Serial.println(WiFi.localIP());
  }

  if (now - previousMillis >= interval) {
    previousMillis = now;
    DHT_SENSOR_READ();
    sendDataToFirebase();
  }

  ir_remote();
  Fan();

  button1.check();
  button2.check();
  button3.check();
  button4.check();
  button5.check();

  // Periodic Firebase connection check
  if (now - lastCheck >= 2000) {
    lastCheck = now;
    if (testFirebaseConnection()) {
      Serial.println("Firebase connection OK");
    } else {
      Serial.println("Firebase connection lost. Attempting reconnection...");
      Firebase.begin(&config, &auth);
    }
    
    // Print current status
    Serial.printf("Temperature: %.2f°C, Humidity: %.2f%%\n", temperature, humidity);
    Serial.printf("Relays: R1=%d, R2=%d, R3=%d, R4=%d\n", relay1, relay2, relay3, relay4);
    Serial.printf("Fan: Power=%d, Speed=%d\n", fan_power, curr_speed);
  }

  checkFirebaseUpdates();
}

// Consolidated button handler
void buttonHandler(int relayPin, int relayNumber, bool &relayState, uint8_t eventType) {
  if (DEBUG_SW) Serial.println("EVENT" + String(relayNumber));
  switch (eventType) {
    case AceButton::kEventPressed:
      if (DEBUG_SW) Serial.println("kEventPressed");
      relayState = true;
      digitalWrite(relayPin, HIGH);
      break;
    case AceButton::kEventReleased:
      if (DEBUG_SW) Serial.println("kEventReleased");
      relayState = false;
      digitalWrite(relayPin, LOW);
      break;
  }
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay" + String(relayNumber), relayState);
}

void button1Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  buttonHandler(R5, 1, relay1, eventType);
}

void button2Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  buttonHandler(R6, 2, relay2, eventType);
}

void button3Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  buttonHandler(R7, 3, relay3, eventType);
}

void button4Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  buttonHandler(R8, 4, relay4, eventType);
}

void button5Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  if (DEBUG_SW) Serial.println("EVENT5");
  switch (eventType) {
    case AceButton::kEventPressed:
      if (DEBUG_SW) Serial.println("kEventPressed");
      if (curr_speed == 0) {
        speed0();
      }
      if (curr_speed == 1) {
        speed1();
      }
      if (curr_speed == 2) {
        speed2();
      }
      if (curr_speed == 3) {
        speed3();
      }
      if (curr_speed == 4) {
        speed4();
      }
      break;
    case AceButton::kEventReleased:
      if (DEBUG_SW) Serial.println("kEventReleased");
      digitalWrite(Speed1, LOW);
      digitalWrite(Speed2, LOW);
      digitalWrite(Speed4, LOW);
      fan_power = 0;
      Firebase.setInt(fbdo, "/outlets/living_room/devices/fan/speed", curr_speed);
      Firebase.setBool(fbdo, "/outlets/living_room/devices/fan/power", fan_power);
      delay(100);
      break;
  }
}

void sendDataToFirebase() {
  Serial.println("Sending data to Firebase...");
  Firebase.setFloat(fbdo, "/outlets/living_room/temperature", temperature) ?
    Serial.println("Temperature sent") : Serial.printf("Temperature send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setFloat(fbdo, "/outlets/living_room/humidity", humidity) ?
    Serial.println("Humidity sent") : Serial.printf("Humidity send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay1", relay1) ?
    Serial.println("Relay 1 sent") : Serial.printf("Relay 1 send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay2", relay2) ?
    Serial.println("Relay 2 sent") : Serial.printf("Relay 2 send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay3", relay3) ?
    Serial.println("Relay 3 sent") : Serial.printf("Relay 3 send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay4", relay4) ?
    Serial.println("Relay 4 sent") : Serial.printf("Relay 4 send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setInt(fbdo, "/outlets/living_room/devices/fan/speed", curr_speed) ?
    Serial.println("Fan speed sent") : Serial.printf("Fan speed send failed: %s\n", fbdo.errorReason().c_str());
  Firebase.setBool(fbdo, "/outlets/living_room/devices/fan/power", fan_power) ?
    Serial.println("Fan power sent") : Serial.printf("Fan power send failed: %s\n", fbdo.errorReason().c_str());
}

void checkFirebaseUpdates() {
  Serial.println("Checking for Firebase updates...");
  if (Firebase.getBool(fbdo, "/outlets/living_room/devices/relay1")) {
    bool newRelay1State = fbdo.boolData();
    if (relay1 != newRelay1State) {
      relay1 = newRelay1State;
      digitalWrite(R5, relay1);
      Serial.printf("Relay 1 updated to: %d\n", relay1);
    }
  } else {
    Serial.printf("Failed to get Relay 1 state: %s\n", fbdo.errorReason().c_str());
  }
  if (Firebase.getBool(fbdo, "/outlets/living_room/devices/relay2")) {
    bool newRelay2State = fbdo.boolData();
    if (relay2 != newRelay2State) {
      relay2 = newRelay2State;
      digitalWrite(R6, relay2);
      Serial.printf("Relay 2 updated to: %d\n", relay2);
    }
  } else {
    Serial.printf("Failed to get Relay 2 state: %s\n", fbdo.errorReason().c_str());
  }
  if (Firebase.getBool(fbdo, "/outlets/living_room/devices/relay3")) {
    bool newRelay3State = fbdo.boolData();
    if (relay3 != newRelay3State) {
      relay3 = newRelay3State;
      digitalWrite(R7, relay3);
      Serial.printf("Relay 3 updated to: %d\n", relay3);
    }
  } else {
    Serial.printf("Failed to get Relay 3 state: %s\n", fbdo.errorReason().c_str());
  }
  if (Firebase.getBool(fbdo, "/outlets/living_room/devices/relay4")) {
    bool newRelay4State = fbdo.boolData();
    if (relay4 != newRelay4State) {
      relay4 = newRelay4State;
      digitalWrite(R8, relay4);
      Serial.printf("Relay 4 updated to: %d\n", relay4);
    }
  } else {
    Serial.printf("Failed to get Relay 4 state: %s\n", fbdo.errorReason().c_str());
  }
  if (Firebase.getInt(fbdo, "/outlets/living_room/devices/fan/speed")) {
    int newSpeed = fbdo.intData();
    if (curr_speed != newSpeed) {
      curr_speed = newSpeed;
      updateFanSpeed();
      Serial.printf("Fan speed updated to: %d\n", curr_speed);
    }
  } else {
    Serial.printf("Failed to get Fan speed: %s\n", fbdo.errorReason().c_str());
  }
  if (Firebase.getBool(fbdo, "/outlets/living_room/devices/fan/power")) {
    bool newFanPower = fbdo.boolData();
    if (fan_power != newFanPower) {
      fan_power = newFanPower;
      updateFanPower();
      Serial.printf("Fan power updated to: %d\n", fan_power);
    }
  } else {
    Serial.printf("Failed to get Fan power: %s\n", fbdo.errorReason().c_str());
  }
}

void updateFanSpeed() {
  if (curr_speed == 0) {
    speed0();
  } else if (curr_speed == 1) {
    speed1();
  } else if (curr_speed == 2) {
    speed2();
  } else if (curr_speed == 3) {
    speed3();
  } else if (curr_speed == 4) {
    speed4();
  }
}

void updateFanPower() {
  if (fan_power) {
    updateFanSpeed();
  } else {
    speed0();
  }
}

void Fan() {
  if (digitalRead(fan_switch) == LOW) {
    if (digitalRead(s1) == LOW && speed1_flag == 1) {
      speed1();
      speed1_flag = 0;
      speed2_flag = speed3_flag = speed4_flag = speed0_flag = 1;
    }
    else if (digitalRead(s2) == LOW && digitalRead(s3) == HIGH && speed2_flag == 1) {
      speed2();
      speed2_flag = 0;
      speed1_flag = speed3_flag = speed4_flag = speed0_flag = 1;
    }
    else if (digitalRead(s2) == LOW && digitalRead(s3) == LOW && speed3_flag == 1) {
      speed3();
      speed3_flag = 0;
      speed1_flag = speed2_flag = speed4_flag = speed0_flag = 1;
    }
    else if (digitalRead(s4) == LOW && speed4_flag == 1) {
      speed4();
      speed4_flag = 0;
      speed1_flag = speed2_flag = speed3_flag = speed0_flag = 1;
    }
    else if (digitalRead(s1) == HIGH && digitalRead(s2) == HIGH && 
             digitalRead(s3) == HIGH && digitalRead(s4) == HIGH && speed0_flag == 1) {
      speed0();
      speed0_flag = 0;
      speed1_flag = speed2_flag = speed3_flag = speed4_flag = 1;
    }
  }
}

// Consolidated fan speed control function
void setFanSpeed(int speed) {
  Serial.println("SPEED " + String(speed));
  digitalWrite(Speed1, LOW);
  digitalWrite(Speed2, LOW);
  digitalWrite(Speed4, LOW);
  curr_speed = speed;
  fan_power = (speed > 0);
  delay(1000);
  
  switch (speed) {
    case 1:
      digitalWrite(Speed1, HIGH);
      break;
    case 2:
      digitalWrite(Speed2, HIGH);
      break;
    case 3:
      digitalWrite(Speed1, HIGH);
      digitalWrite(Speed2, HIGH);
      break;
    case 4:
      digitalWrite(Speed4, HIGH);
      break;
  }
  
  // Keep Firebase updates
  Firebase.setInt(fbdo, "/outlets/living_room/devices/fan/speed", curr_speed);
  Firebase.setBool(fbdo, "/outlets/living_room/devices/fan/power", fan_power);
}

// Simplified speed functions
void speed0() { setFanSpeed(0); }
void speed1() { setFanSpeed(1); }
void speed2() { setFanSpeed(2); }
void speed3() { setFanSpeed(3); }
void speed4() { setFanSpeed(4); }

void DHT_SENSOR_READ() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  humidity = h;
  temperature = t;

  Serial.print("temp = ");
  Serial.println(t);
  Serial.print("Humi = ");
  Serial.println(h);
}

void ir_remote() {
  if (DEBUG_SW) Serial.println("Inside IR REMOTE");
  if (irrecv.decode(&results)) {
    if (DEBUG_SW) Serial.println(results.value, HEX);  //print the HEX code
    switch (results.value) {
      case IR_Relay1:
        switch_ON_Flag1_previous_I = !switch_ON_Flag1_previous_I;
        digitalWrite(R5, switch_ON_Flag1_previous_I);
        if (DEBUG_SW) Serial.println("RELAY1 ON");
        relay1 = switch_ON_Flag1_previous_I;
        Firebase.setBool(fbdo, "/outlets/living_room/devices/relay1", relay1);
        delay(100);
        break;
      case IR_Relay2:
        switch_ON_Flag2_previous_I = !switch_ON_Flag2_previous_I;
        digitalWrite(R6, switch_ON_Flag2_previous_I);
        relay2 = switch_ON_Flag2_previous_I;
        Firebase.setBool(fbdo, "/outlets/living_room/devices/relay2", relay2);
        delay(100);
        break;
      case IR_Relay3:
        switch_ON_Flag3_previous_I = !switch_ON_Flag3_previous_I;
        digitalWrite(R7, switch_ON_Flag3_previous_I);
        relay3 = switch_ON_Flag3_previous_I;
        Firebase.setBool(fbdo, "/outlets/living_room/devices/relay3", relay3);
        delay(100);
        break;
      case IR_Relay4:
        switch_ON_Flag4_previous_I = !switch_ON_Flag4_previous_I;
        digitalWrite(R8, switch_ON_Flag4_previous_I);
        relay4 = switch_ON_Flag4_previous_I;
        Firebase.setBool(fbdo, "/outlets/living_room/devices/relay4", relay4);
        delay(100);
        break;
      case IR_Relay_All_Off:
        All_Lights_Off();
        break;
      case IR_Relay_All_On:
        All_Lights_On();
        break;
      case IR_Fan_on:
        if (curr_speed == 0) {
          speed0();
        } else if (curr_speed == 1) {
          speed1();
        } else if (curr_speed == 2) {
          speed2();
        } else if (curr_speed == 3) {
          speed3();
        } else if (curr_speed == 4) {
          speed4();
        }
        break;
      case IR_Fan_off:
        speed0();
        break;
      case IR_Speed_Up:
        if (curr_speed == 1) {
          speed2();
        } else if (curr_speed == 2) {
          speed3();
        } else if (curr_speed == 3) {
          speed4();
        }
        break;
      case IR_Speed_Dw:
        if (curr_speed == 2) {
          speed1();
        } else if (curr_speed == 3) {
          speed2();
        } else if (curr_speed == 4) {
          speed3();
        }
        break;
      default: break;
    }
    irrecv.resume();
  }
  DEBUG_SW = 0;
}

void All_Lights_Off() {
  switch_ON_Flag1_previous_I = 0;
  digitalWrite(R5, LOW);
  relay1 = 0;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay1", relay1);

  switch_ON_Flag2_previous_I = 0;
  digitalWrite(R6, LOW);
  relay2 = 0;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay2", relay2);

  switch_ON_Flag3_previous_I = 0;
  digitalWrite(R7, LOW);
  relay3 = 0;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay3", relay3);

  switch_ON_Flag4_previous_I = 0;
  digitalWrite(R8, LOW);
  relay4 = 0;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay4", relay4);
}

void All_Lights_On() {
  switch_ON_Flag1_previous_I = 1;
  digitalWrite(R5, HIGH);
  relay1 = 1;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay1", relay1);

  switch_ON_Flag2_previous_I = 1;
  digitalWrite(R6, HIGH);
  relay2 = 1;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay2", relay2);

  switch_ON_Flag3_previous_I = 1;
  digitalWrite(R7, HIGH);
  relay3 = 1;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay3", relay3);

  switch_ON_Flag4_previous_I = 1;
  digitalWrite(R8, HIGH);
  relay4 = 1;
  Firebase.setBool(fbdo, "/outlets/living_room/devices/relay4", relay4);
}