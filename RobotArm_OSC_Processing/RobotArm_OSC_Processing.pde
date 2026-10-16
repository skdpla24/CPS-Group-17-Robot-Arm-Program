/*
  processing_osc_to_arduino
  CPS Team 17

  Functions:
  1. Open camera
  2. Calculate the screen-area ratio of red, blue, green and orange
  3. Receive Wekinator class output through OSC
  4. Send class 1-4 to Arduino only when the matching colour
     occupies more than one-third of the camera frame
*/

import oscP5.*;
import netP5.*;
import processing.serial.*;
import processing.video.*;

// 1. OSC and Serial
OscP5 oscP5;
NetAddress wekinatorInput;
Serial port;

// 2. Camera
Capture cam;

// 3. Class and colour ratios
int arduinoMessage = 0;

float redRatio = 0;
float blueRatio = 0;
float greenRatio = 0;
float orangeRatio = 0;

final float AREA_THRESHOLD = 1.0 / 3.0;
int lastInputTime = 0;

// Wekinator class IDs must match these colours:
// Class 1 = Red -> Base servo on Arduino D3
// Class 2 = Blue -> Left servo on Arduino D5
// Class 3 = Green -> Right servo on Arduino D6
// Class 4 = Orange -> Up/gripper servo on Arduino D9

void setup() {
  size(640, 480);
  pixelDensity(1);

  // List available serial ports
  println("Available serial ports:");
  printArray(Serial.list());

  // Arduino port and baud rate
  port = new Serial(this, "/dev/cu.usbmodem21201", 9600);

  // Listen for Wekinator OSC outputs on port 12000
  oscP5 = new OscP5(this, 12000);
  wekinatorInput = new NetAddress("127.0.0.1", 6448);

  // Start camera
  String[] cameras = Capture.list();

  println("Available cameras:");
  printArray(cameras);

  if (cameras.length > 0) {
    cam = new Capture(this, cameras[0]);
    cam.start();
    println("Camera started: " + cameras[0]);
  } else {
    println("ERROR: No camera found.");
  }

  textSize(18);
  textAlign(LEFT, TOP);
}

void draw() {
  background(0);

  // Read and display camera
  if (cam != null) {
    if (cam.available()) {
      cam.read();
    }

    image(cam, 0, 0, width, height);

    // Calculate colour ratios continuously
    calculateColourAreas();
  }

  // Send four colour-area inputs to Wekinator about 15 times per second
  if (millis() - lastInputTime >= 66) {
    sendInputs();
    lastInputTime = millis();
  }
  // Display current class and colour ratios
  fill(255);
  text("Class: " + arduinoMessage, 10, 10);
  text("Red: " + nf(redRatio * 100, 0, 1) + "%", 10, 35);
  text("Blue: " + nf(blueRatio * 100, 0, 1) + "%", 10, 60);
  text("Green: " + nf(greenRatio * 100, 0, 1) + "%", 10, 85);
  text("Orange: " + nf(orangeRatio * 100, 0, 1) + "%", 10, 110);
  text("Threshold: 33.3%", 10, 135);
}

// 4. Calculate the area ratio of each colour
void calculateColourAreas() {

  cam.loadPixels();

  int redCount = 0;
  int blueCount = 0;
  int greenCount = 0;
  int orangeCount = 0;

  colorMode(HSB, 360, 100, 100);

  for (int i = 0; i < cam.pixels.length; i++) {
    color c = cam.pixels[i];

    float h = hue(c);
    float s = saturation(c);
    float b = brightness(c);

    // Ignore low-saturation or very dark pixels
    if (s < 40 || b < 25) {
      continue;
    }

    // Red
    if (h < 15 || h > 345) {
      redCount++;
    }
    // Blue
    else if (h >= 190 && h <= 250) {
      blueCount++;
    }
    // Green
    else if (h >= 80 && h <= 160) {
      greenCount++;
    }
    // Orange
    else if (h >= 15 && h < 45) {
      orangeCount++;
    }
  }

  float totalPixels = cam.pixels.length;

  if (totalPixels > 0) {
    redRatio = redCount / totalPixels;
    blueRatio = blueCount / totalPixels;
    greenRatio = greenCount / totalPixels;
    orangeRatio = orangeCount / totalPixels;
  }

  colorMode(RGB, 255);
}

// Send red, blue, green and orange ratios as four OSC float inputs
void sendInputs() {
  OscMessage inputMessage = new OscMessage("/wek/inputs");
  inputMessage.add(redRatio);
  inputMessage.add(blueRatio);
  inputMessage.add(greenRatio);
  inputMessage.add(orangeRatio);
  oscP5.send(inputMessage, wekinatorInput);
}


// 5. Receive Wekinator OSC output 
void oscEvent(OscMessage theOscMessage) {

  if (theOscMessage.checkAddrPattern("/wek/outputs")) {

    if (theOscMessage.checkTypetag("f")) {

      float firstValue =
        theOscMessage.get(0).floatValue();

    int classId = round(firstValue);

if (classId < 1 || classId > 4) {
  arduinoMessage = -1;
  return;
}
      println("Received Wekinator class: " + classId);

      float colorAreaRatio = 0;

      // Find the ratio corresponding to the predicted class
      if (classId == 1) {
        colorAreaRatio = redRatio;
      } else if (classId == 2) {
        colorAreaRatio = blueRatio;
      } else if (classId == 3) {
        colorAreaRatio = greenRatio;
      } else if (classId == 4) {
        colorAreaRatio = orangeRatio;
      } else {
        return;
      }

      println("Matching colour area: " +
              nf(colorAreaRatio * 100, 0, 1) + "%");

      // Send only if matching colour exceeds one-third
      if (colorAreaRatio > AREA_THRESHOLD) {
        updateArduino(classId);
      } else {
        // Reset so the same class can trigger again
        arduinoMessage = -1;
      }

      return;
    }
  }

  println("Received OSC message: " +
          theOscMessage.addrPattern());
}

// 6. Send command to Arduino 
void updateArduino(int newMessage) {

  // Avoid repeatedly sending the same class while it remains active
  if (newMessage != arduinoMessage) {

    arduinoMessage = newMessage;

    println("Sending to Arduino: " + arduinoMessage);

    // Send raw byte 1, 2, 3 or 4.
    // This matches Arduino's switch cases: case 1, case 2, etc.
    port.write(arduinoMessage);
  }
}
