import processing.serial.*;
PImage brickImageFull; // 完整砖块的贴图
PImage brickImageDamaged; // 受损砖块的贴图
PImage backgroundImage; // 背景贴图
Serial serial;

// 球的变量
float ballX, ballY; 
float ballSpeedX = 3; 
float ballSpeedY = 3;
float ballDiameter = 20;

// 挡板的变量
float paddleX;
float paddleWidth = 150;
float paddleHeight = 10;
float paddleSpeed = 10;

// 砖块的变量
int brickRows = 5;
int brickCols = 10;
float brickWidth;
float brickHeight = 20;
int[][] bricks; // 使用整型数组来存储砖块的生命值
float[][] brickFallSpeeds; // 砖块的下落速度
float[][] brickPositions; // 砖块的当前位置

int ballColor; // 小球的颜色
int lastColorChangeTime = 0; // 上次颜色变换的时间

// 已打掉的砖块数量
int destroyedBricks = 0;

// 游戏结束标志
boolean gameEnded = false;
boolean gameWon = false;
// 生命值
int lives = 5;

void setup() {
  size(800, 600);
  
  serial = new Serial(this, "com4", 9600);
  ballX = width / 2;
  ballY = height / 2;
  paddleX = (width / 2 - paddleWidth / 2) + width / 3;
  brickWidth = width / brickCols;
  
  // 加载贴图
  brickImageFull = loadImage("brickImageFull.png"); // 砖块完整状态的贴图
  brickImageDamaged = loadImage("brickImageDamaged.png"); // 砖块受损状态的贴图
  backgroundImage = loadImage("background.png"); // 背景贴图
  
  generateRandomBricks();
  
  ballColor = color(random(255), random(255), random(255)); // 初始化小球颜色
}

void draw() {
  background(backgroundImage); // 绘制背景

  if (gameEnded) {
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("game over", width / 2, height / 2);
    return;
  }
  
  if (gameWon) {
    fill(0);
    textAlign(CENTER, CENTER);
    textSize(32);
    text("you win", width / 2, height / 2);
    return;
  }

  // 检查是否需要更新小球的颜色
  if (millis() - lastColorChangeTime > 500) { // 每隔一秒变换一次颜色
    ballColor = color(random(255), random(255), random(255));
    lastColorChangeTime = millis();
  }

  // 画球
  fill(ballColor);  // 设置球的填充颜色为当前颜色
  ellipse(ballX, ballY, ballDiameter, ballDiameter);

  // 画挡板
  fill(50, 255, 0);  // 设置挡板的填充颜色为绿色
  rect(paddleX, height - paddleHeight, paddleWidth, paddleHeight);

  // 画砖块
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      if (bricks[i][j] > 0) {
        float brickX = j * brickWidth;
        float brickY = brickPositions[i][j];
        if (bricks[i][j] == 2) {
          image(brickImageFull, brickX, brickY, brickWidth, brickHeight); // 画完整砖块
        } else if (bricks[i][j] == 1) {
          image(brickImageDamaged, brickX, brickY, brickWidth, brickHeight); // 画受损砖块
        }
      } else if (bricks[i][j] == 0 && brickPositions[i][j] < height) {
        // 下落的砖块
        float brickX = j * brickWidth;
        float brickY = brickPositions[i][j];
        image(brickImageDamaged, brickX, brickY, brickWidth, brickHeight);
        brickPositions[i][j] += brickFallSpeeds[i][j]; // 增加下落速度
        brickFallSpeeds[i][j] += 0.1; // 模拟重力加速度
      }
    }
  }

  // 画剩余的生命值
  fill(255, 0, 0);  // 设置红色
  for (int i = 0; i < lives; i++) {
    ellipse(20 + i * 30, height - 20, 20, 20); // 每个小球的直径为20，间隔为30
  }

  // 球的移动和碰撞检测
  ballX += ballSpeedX;
  ballY += ballSpeedY;
  
  // 碰撞检测
  if (ballX < ballDiameter / 2 || ballX > width - ballDiameter / 2) {
    ballSpeedX *= -1; // 左右边界反弹
  }
  if (ballY < ballDiameter / 2) {
    ballSpeedY *= -1; // 上边界反弹
  }
  if (ballY > height - ballDiameter / 2) {
    // 减少生命值
    lives--;
    if (lives <= 0) {
      gameEnded = true; // 游戏结束
    } else {
      // 重置球的位置和速度
      ballX = width / 2;
      ballY = height / 2;
      ballSpeedX = 3;
      ballSpeedY = 3;
      paddleSpeed = 10;
      ballDiameter = 20;
      paddleWidth = 150;
      destroyedBricks = 0; // 重置已打掉的砖块数量
    }
  }
  
  // 挡板碰撞
  if (ballY + ballDiameter / 2 > height - paddleHeight && 
      ballX > paddleX && ballX < paddleX + paddleWidth) {
    ballSpeedY *= -1;
  }
  
  // 砖块碰撞检测
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      if (bricks[i][j] > 0) {
        float brickX = j * brickWidth;
        float brickY = i * brickHeight;
        if (ballX > brickX && ballX < brickX + brickWidth &&
            ballY - ballDiameter / 2 < brickY + brickHeight &&
            ballY + ballDiameter / 2 > brickY) {
          ballSpeedY *= -1;
          bricks[i][j]--; // 减少砖块的生命值
          if (bricks[i][j] == 0) {
            destroyedBricks++; // 增加已打掉的砖块数量
          }
          
          // 每打掉一个砖块增加球的速度
          if (destroyedBricks % 3 == 0) { // 每3个砖块增加一次速度
            ballSpeedX *= 1.1; // X轴速度增加10%
            ballSpeedY *= 1.1; // Y轴速度增加10%
            paddleSpeed *= 1.1;
            ballDiameter *= 1.05;
            paddleWidth *= 1.05; 
          }
        }
      }
    }
  }

  // 检查是否所有砖块都被击碎
  boolean allBricksDestroyed = true;
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      if (bricks[i][j] > 0) {
        allBricksDestroyed = false;
        break;
      }
    }
    if (!allBricksDestroyed) {
      break;
    }
  }

  if (allBricksDestroyed) {
    gameWon = true;
  }

  // 挡板移动
   // 检查是否有数据可用
  while (serial.available() > 0) {
    String data = serial.readStringUntil('\n'); // 读取一行数据
    if (data != null) {
      data = trim(data);  // 去除字符串首尾的空白字符
      
      println(data);
      
      int value = int(data);  // 将字符串转换为 int 值
      value *= -1;
      if (value > 200) {
        value = 200;
      } else if (value < -200) {
        value = -200;
      }
      value += 200;
      value *= 2;
      paddleX = value;
    }
  }

  // 防止挡板移出画布
  paddleX = constrain(paddleX, 0, width - paddleWidth);
}

// 随机生成砖块布局
void generateRandomBricks() {
  bricks = new int[brickRows][brickCols];
  brickFallSpeeds = new float[brickRows][brickCols];
  brickPositions = new float[brickRows][brickCols];
  
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      float R=random(1);
      if(R>0.4){ 
          bricks[i][j]=2;
       }else if(R<0.2){
         bricks[i][j] = 1; // 70% 的概率砖块存在并且有2条命
       }
       else bricks[i][j]=0;
      //bricks[i][j] = (R > 0.3) ? 2 : 0; // 70% 的概率砖块存在并且有2条命
      brickFallSpeeds[i][j] = 0; // 初始下落速度为0
      brickPositions[i][j] = i * brickHeight; // 砖块的初始位置
    }
  }
}
