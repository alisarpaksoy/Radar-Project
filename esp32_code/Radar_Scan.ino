#include <Wire.h>
#include <VL53L1X.h>
#include <ESP32Servo.h>

VL53L1X sensor;
Servo myServo;

int servoPin = 18;

bool scanning = false;   // servo starts stopped
int angle = 0;
int direction = 1;

void setup() {
  Serial.begin(115200);

  Wire.begin(21, 22); // SDA = D21, SCL = D22

  sensor.setTimeout(500);

  if (!sensor.init()) {
    Serial.println("VL53L1X not detected");
    while (1);
  }

  sensor.startContinuous(50);

  myServo.attach(servoPin);
  myServo.write(90);   // start at center

  Serial.println("Servo + VL53L1X ready");
}

void loop() {
  // Read command from MATLAB
  if (Serial.available()) {
    String command = Serial.readStringUntil('\n');
    command.trim();

    if (command == "START") {
      scanning = true;
    }

    if (command == "STOP") {
      scanning = false;
      myServo.write(90);   // stop at center
    }
  }

  // Only scan if MATLAB sends START
  if (scanning) {
    myServo.write(angle);
    delay(10);

    printDistance(angle);

    angle = angle + direction;

    if (angle >= 180) {
      angle = 180;
      direction = -1;
    }

    if (angle <= 0) {
      angle = 0;
      direction = 1;
    }
  }
}

void printDistance(int angle) {
  int distance = sensor.read();

  Serial.print("Angle: ");
  Serial.print(angle);
  Serial.print(" | Distance: ");
  Serial.print(distance);
  Serial.println(" mm");
}