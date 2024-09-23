#include "DHT.h"
#include <IRremote.h>   // https://github.com/Arduino-IRremote/Arduino-IRremote (3.6.1)
#include <AceButton.h>  // https://github.com/bxparks/AceButton (1.9.2)
#include <WiFi.h>
#include <FirebaseESP32.h>
#include <ArduinoJson.h>

// Firebase credentials
#define FIREBASE_HOST "your-project-id.firebaseio.com"
#define FIREBASE_AUTH "YOUR_FIREBASE_DATABASE_SECRET"

// WiFi credentials
#define WIFI_SSID "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

FirebaseData firebaseData;

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

#define NUM_OUTLETS 4
String outletIds[NUM_OUTLETS] = {"outlet1", "outlet2", "outlet3", "outlet4"};
String deviceIds[NUM_OUTLETS] = {"", "", "", ""};
bool deviceStates[NUM_OUTLETS] = {false, false, false, false};

void setup() {
  // Initialize serial and wait for port to open:
  Serial.begin(115200);

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

  // Connect to WiFi
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());

  // Connect to Firebase
  Firebase.begin(FIREBASE_HOST, FIREBASE_AUTH);
  Firebase.reconnectWiFi(true);

  for (int i = 0; i < NUM_OUTLETS; i++) {
    String path = "/outlets/" + outletIds[i];
    Firebase.setStreamCallback(firebaseData, streamCallback, streamTimeoutCallback, path.c_str());
  }

  delay(1500);
}

void loop() {
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
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

  if (Firebase.readStream(firebaseData)) {
    streamCallback(firebaseData.streamData());
  }
}

void button1Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  if (DEBUG_SW) Serial.println("EVENT1");
  switch (eventType) {
    case AceButton::kEventPressed:
      if (DEBUG_SW) Serial.println("kEventPressed");
      relay1 = 1;
      digitalWrite(R5, HIGH);
      Firebase.setBool(firebaseData, "/relay1", relay1);
      break;
    case AceButton::kEventReleased:
      if (DEBUG_SW) Serial.println("kEventReleased");
      relay1 = 0;
      digitalWrite(R5, LOW);
      Firebase.setBool(firebaseData, "/relay1", relay1);
      break;
  }
}

void button2Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  if (DEBUG_SW) Serial.println("EVENT2");
  switch (eventType) {
    case AceButton::kEventPressed:
      if (DEBUG_SW) Serial.println("kEventPressed");
      relay2 = 1;
      digitalWrite(R6, HIGH);
      Firebase.setBool(firebaseData, "/relay2", relay2);
      break;
    case AceButton::kEventReleased:
      if (DEBUG_SW) Serial.println("kEventReleased");
      relay2 = 0;
      digitalWrite(R6, LOW);
      Firebase.setBool(firebaseData, "/relay2", relay2);
      break;
  }
}

void button3Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  if (DEBUG_SW) Serial.println("EVENT3");
  switch (eventType) {
    case AceButton::kEventPressed:
      if (DEBUG_SW) Serial.println("kEventPressed");
      relay3 = 1;
      digitalWrite(R7, HIGH);
      Firebase.setBool(firebaseData, "/relay3", relay3);
      break;
    case AceButton::kEventReleased:
      if (DEBUG_SW) Serial.println("kEventReleased");
      relay3 = 0;
      digitalWrite(R7, LOW);
      Firebase.setBool(firebaseData, "/relay3", relay3);
      break;
  }
}

void button4Handler(AceButton* button, uint8_t eventType, uint8_t buttonState) {
  if (DEBUG_SW) Serial.println("EVENT4");
  switch (eventType) {
    case AceButton::kEventPressed:
      if (DEBUG_SW) Serial.println("kEventPressed");
      relay4 = 1;
      digitalWrite(R8, HIGH);
      Firebase.setBool(firebaseData, "/relay4", relay4);
      break;
    case AceButton::kEventReleased:
      if (DEBUG_SW) Serial.println("kEventReleased");
      relay4 = 0;
      digitalWrite(R8, LOW);
      Firebase.setBool(firebaseData, "/relay4", relay4);
      break;
  }
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
      fan.setSwitch(0);
      fan_power = 0;
      Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
      Firebase.setBool(firebaseData, "/fan/power", fan_power);
      delay(100);
      break;
  }
}

void sendDataToFirebase() {
  Firebase.setFloat(firebaseData, "/sensors/temperature", temperature);
  Firebase.setFloat(firebaseData, "/sensors/humidity", humidity);

  for (int i = 0; i < NUM_OUTLETS; i++) {
    String path = "/outlets/" + outletIds[i];
    Firebase.setString(firebaseData, path + "/deviceId", deviceIds[i]);
    Firebase.setBool(firebaseData, path + "/state", deviceStates[i]);
  }

  Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
  Firebase.setBool(firebaseData, "/fan/power", fan_power);
}

void streamCallback(StreamData data) {
  String path = data.dataPath();
  FirebaseJson json = data.jsonObject();
  FirebaseJsonData jsonData;

  if (json.get(jsonData, "deviceId")) {
    String deviceId = jsonData.stringValue;
    int outletIndex = getOutletIndex(path);
    if (outletIndex != -1) {
      deviceIds[outletIndex] = deviceId;
    }
  }

  if (json.get(jsonData, "state")) {
    bool state = jsonData.boolValue;
    int outletIndex = getOutletIndex(path);
    if (outletIndex != -1) {
      deviceStates[outletIndex] = state;
      updateDeviceState(outletIndex);
    }
  }
}

void streamTimeoutCallback(bool timeout) {
  if (timeout) {
    Serial.println("Stream timeout, resume streaming...");
  }
}

int getOutletIndex(String path) {
  for (int i = 0; i < NUM_OUTLETS; i++) {
    if (path.indexOf(outletIds[i]) != -1) {
      return i;
    }
  }
  return -1;
}

void updateDeviceState(int outletIndex) {
  switch (outletIndex) {
    case 0:
      digitalWrite(R5, deviceStates[outletIndex] ? HIGH : LOW);
      break;
    case 1:
      digitalWrite(R6, deviceStates[outletIndex] ? HIGH : LOW);
      break;
    case 2:
      digitalWrite(R7, deviceStates[outletIndex] ? HIGH : LOW);
      break;
    case 3:
      digitalWrite(R8, deviceStates[outletIndex] ? HIGH : LOW);
      break;
  }
}

void Fan() {
  if (digitalRead(fan_switch) == LOW) {
    if (digitalRead(s1) == LOW && speed1_flag == 1) {
      speed1();
      speed1_flag = 0;
      speed2_flag = 1;
      speed3_flag = 1;
      speed4_flag = 1;
      speed0_flag = 1;
    }
    if (digitalRead(s2) == LOW && digitalRead(s3) == HIGH && speed2_flag == 1) {
      speed2();
      speed1_flag = 1;
      speed2_flag = 0;
      speed3_flag = 1;
      speed4_flag = 1;
      speed0_flag = 1;
    }
    if (digitalRead(s2) == LOW && digitalRead(s3) == LOW && speed3_flag == 1) {
      speed3();
      speed1_flag = 1;
      speed2_flag = 1;
      speed3_flag = 0;
      speed4_flag = 1;
      speed0_flag = 1;
    }
    if (digitalRead(s4) == LOW && speed4_flag == 1) {
      speed4();
      speed1_flag = 1;
      speed2_flag = 1;
      speed3_flag = 1;
      speed4_flag = 0;
      speed0_flag = 1;
    }
    if (digitalRead(s1) == HIGH && digitalRead(s2) == HIGH && digitalRead(s3) == HIGH && digitalRead(s4) == HIGH && speed0_flag == 1) {
      speed0();
      speed1_flag = 1;
      speed2_flag = 1;
      speed3_flag = 1;
      speed4_flag = 1;
      speed0_flag = 0;
    }
  }
}

// Fan Speed Control

void speed0() {
  //All Relays Off - Fan at speed 0
  Serial.println("SPEED 0");
  digitalWrite(Speed1, LOW);
  digitalWrite(Speed2, LOW);
  digitalWrite(Speed4, LOW);
  fan.setSwitch(0);
  fan.setBrightness(0);
  curr_speed = 0;
  fan_power = 0;
  Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
  Firebase.setBool(firebaseData, "/fan/power", fan_power);
  delay(1000);
}

void speed1() {
  //Speed1 Relay On - Fan at speed 1
  Serial.println("SPEED 1");
  digitalWrite(Speed1, LOW);
  digitalWrite(Speed2, LOW);
  digitalWrite(Speed4, LOW);
  fan.setSwitch(1);
  fan.setBrightness(25);
  curr_speed = 1;
  fan_power = 1;
  Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
  Firebase.setBool(firebaseData, "/fan/power", fan_power);
  delay(1000);
  digitalWrite(Speed1, HIGH);
}

void speed2() {
  //Speed2 Relay On - Fan at speed 2
  Serial.println("SPEED 2");
  digitalWrite(Speed1, LOW);
  digitalWrite(Speed2, LOW);
  digitalWrite(Speed4, LOW);
  fan.setSwitch(1);
  fan.setBrightness(50);
  curr_speed = 2;
  fan_power = 1;
  Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
  Firebase.setBool(firebaseData, "/fan/power", fan_power);
  delay(1000);
  digitalWrite(Speed2, HIGH);
}

void speed3() {
  //Speed1 & Speed2 Relays On - Fan at speed 3
  Serial.println("SPEED 3");
  digitalWrite(Speed1, LOW);
  digitalWrite(Speed2, LOW);
  digitalWrite(Speed4, LOW);
  fan.setSwitch(1);
  fan.setBrightness(75);
  curr_speed = 3;
  fan_power = 1;
  Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
  Firebase.setBool(firebaseData, "/fan/power", fan_power);
  delay(1000);
  digitalWrite(Speed1, HIGH);
  digitalWrite(Speed2, HIGH);
}

void speed4() {
  //Speed4 Relay On - Fan at speed 4
  Serial.println("SPEED 4");
  digitalWrite(Speed1, LOW);
  digitalWrite(Speed2, LOW);
  digitalWrite(Speed4, LOW);
  fan.setSwitch(1);
  fan.setBrightness(100);
  curr_speed = 4;
  fan_power = 1;
  Firebase.setInt(firebaseData, "/fan/speed", curr_speed);
  Firebase.setBool(firebaseData, "/fan/power", fan_power);
  delay(1000);
  digitalWrite(Speed4, HIGH);
}

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
        Firebase.setBool(firebaseData, "/relay1", relay1);
        delay(100);
        break;
      case IR_Relay2:
        switch_ON_Flag2_previous_I = !switch_ON_Flag2_previous_I;
        digitalWrite(R6, switch_ON_Flag2_previous_I);
        relay2 = switch_ON_Flag2_previous_I;
        Firebase.setBool(firebaseData, "/relay2", relay2);
        delay(100);
        break;
      case IR_Relay3:
        switch_ON_Flag3_previous_I = !switch_ON_Flag3_previous_I;
        digitalWrite(R7, switch_ON_Flag3_previous_I);
        relay3 = switch_ON_Flag3_previous_I;
        Firebase.setBool(firebaseData, "/relay3", relay3);
        delay(100);
        break;
      case IR_Relay4:
        switch_ON_Flag4_previous_I = !switch_ON_Flag4_previous_I;
        digitalWrite(R8, switch_ON_Flag4_previous_I);
        relay4 = switch_ON_Flag4_previous_I;
        Firebase.setBool(firebaseData, "/relay4", relay4);
        delay(100);
        break;
      case IR_Relay_All_Off:
        All_Lights_Off();
        break;
      case IR_Relay_All_On:
        All_Lights_On();
        break;
      case IR_Fan_on:
        fan.setSwitch(1);
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
        fan.setSwitch(0);
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
  Firebase.setBool(firebaseData, "/relay1", relay1);

  switch_ON_Flag2_previous_I = 0;
  digitalWrite(R6, LOW);
  relay2 = 0;
  Firebase.setBool(firebaseData, "/relay2", relay2);

  switch_ON_Flag3_previous_I = 0;
  digitalWrite(R7, LOW);
  relay3 = 0;
  Firebase.setBool(firebaseData, "/relay3", relay3);

  switch_ON_Flag4_previous_I = 0;
  digitalWrite(R8, LOW);
  relay4 = 0;
  Firebase.setBool(firebaseData, "/relay4", relay4);
}

void All_Lights_On() {
  switch_ON_Flag1_previous_I = 1;
  digitalWrite(R5, HIGH);
  relay1 = 1;
  Firebase.setBool(firebaseData, "/relay1", relay1);

  switch_ON_Flag2_previous_I = 1;
  digitalWrite(R6, HIGH);
  relay2 = 1;
  Firebase.setBool(firebaseData, "/relay2", relay2);

  switch_ON_Flag3_previous_I = 1;
  digitalWrite(R7, HIGH);
  relay3 = 1;
  Firebase.setBool(firebaseData, "/relay3", relay3);

  switch_ON_Flag4_previous_I = 1;
  digitalWrite(R8, HIGH);
  relay4 = 1;
  Firebase.setBool(firebaseData, "/relay4", relay4);
}