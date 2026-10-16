// CPS Team 17, Arduino Debug + Control code
// Written by Andrea Spagnolo; Bianca Zhong; Zhiru Niu
// Comments Language: English/Chinese

#include <Servo.h>

// Naming Each Servo (viewed from behind the arm)
// 四个舵机的名字（从机械臂后方看）

Servo Base;    // Base rotation
Servo Left;    // Left arm: lift
Servo Right;   // Right arm: extension
Servo Up;      // Gripper: open and close

// Signal pin for each servo / 各个舵机信号线连接的引脚
const int BASE_PIN = 3;
const int LEFT_PIN = 5;
const int RIGHT_PIN = 6;
const int UP_PIN = 9;

// Store the incoming serial command / 保存串口接收到的指令
int servoCode = 0;

// Start serial communication / 开启串口通信
void setup() {
  Serial.begin(9600);

  // Attach each servo to its signal pin / 将各舵机连接到对应信号引脚
  Base.attach(BASE_PIN);
  Left.attach(LEFT_PIN);
  Right.attach(RIGHT_PIN);
  Up.attach(UP_PIN);

  // Wait 1 second before testing / 等待 1 秒后开始测试
  delay(1000);


  // Test each servo in turn: start at 90°, move to its test position,
  // then return to 90°. Wait 800 ms after each command.
  // 依次测试四个舵机：从 90° 开始，移动到各自的测试位置，
  // 最后回到 90°。每次发送指令后等待 800 毫秒。
  //
  // Completion messages confirm the sequence has finished;
  // actual movement must be checked visually.
  // 完成提示仅表示指令序列执行结束，实际动作需人工观察确认。
  
  // Test Servo 1: Base
  Serial.println("Testing Base");
  Base.write(90);
  delay(800);
  Base.write(105);
  delay(800);
  Base.write(90);
  delay(800);
  
  Serial.println("Self-test of Base completed");

  // Test Servo 2: Left
  Serial.println("Testing Left");
  Left.write(90);
  delay(800);
  Left.write(110);
  delay(800);
  Left.write(90);
  delay(800);
  Serial.println("Self-test of Left completed");

  // Test Servo 3: Right
  Serial.println("Testing Right");
  Right.write(90);
  delay(800);
  Right.write(150);
  delay(800);
  Right.write(90);
  delay(800);
  Serial.println("Self-test of Right completed");

  //Test Servo 4: Up
  Serial.println("Testing Up");
  Up.write(90);
  delay(800);
  Up.write(70);
  delay(800);
  Up.write(144);
  delay(800);
  Up.write(90);
  delay(800);
  Serial.println("Self-test of Up completed");

  Serial.println("Self-test of 4 servos completed");
  
  // Indicate that startup tests are finished and wait for commands
  // 提示启动测试已结束，程序即将等待控制指令
  Serial.println("Waiting for classes 1-4");
}


void loop() {
 
 // Continuously check for incoming serial commands
 // 持续检查串口是否收到指令
  if (Serial.available() > 0) {
    // Read one command byte / 读取一个指令字节
    servoCode = Serial.read();

    // Select the action matching the received class
    // 根据收到的类别编号选择对应动作
    switch (servoCode) {

      case 1:
        // Red: move the base to 74°, 108°, then return to 90°
        // 红色：基座依次移动到 74°、108°，最后回到 90°
        Base.write(74);
        delay(500);

        Base.write(108);
        delay(500);

        Base.write(90);
        delay(500);
        // Exit the switch after this action / 动作结束后退出 switch
        break;

      case 2:
        // Blue: move the left arm to 60°, 126°, then return to 90°
        // 蓝色：左臂依次移动到 60°、126°，最后回到 90°
        Left.write(60);
        delay(500);

        Left.write(126);
        delay(500);

        Left.write(90);
        delay(500);
        // Exit the switch after this action / 动作结束后退出 switch
        break;

      case 3:
        // Green: move the right arm to 58°, 168°, then return to 90°
        // 绿色：右臂依次移动到 58°、168°，最后回到 90°
        Right.write(58);
        delay(500);

        Right.write(168);
        delay(500);

        Right.write(90);
        delay(500);
        // Exit the switch after this action / 动作结束后退出 switch
        break;

      case 4:
        // Orange: open the gripper to 70°, close to 144°, then return to 90°
        // 橙色：钳子打开到 70°，闭合到 144°，最后回到 90°
        Up.write(70);
        delay(500);

        Up.write(144);
        delay(500);

        Up.write(90);
        delay(500);
        // Exit the switch after this action / 动作结束后退出 switch
        break;
    }
  }
}