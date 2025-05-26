import processing.serial.*;
PImage brickImageFull; // 完全なブロックのテクスチャ
PImage brickImageDamaged; // 損傷したブロックのテクスチャ
PImage backgroundImage; // 背景のテクスチャ
Serial serial;

// ボールに関する変数
float ballX, ballY; 
float ballSpeedX = 3; 
float ballSpeedY = 3;
float ballDiameter = 20;

// パドルに関する変数
float paddleX;
float paddleWidth = 150;
float paddleHeight = 10;
float paddleSpeed = 10;

// ブロックに関する変数
int brickRows = 5;
int brickCols = 10;
float brickWidth;
float brickHeight = 20;
int[][] bricks; // ブロックの耐久値を格納する配列
float[][] brickFallSpeeds; // ブロックの落下速度
float[][] brickPositions; // ブロックの現在位置

int ballColor; // ボールの色
int lastColorChangeTime = 0; // 最後に色が変わった時刻

// 壊されたブロックの数
int destroyedBricks = 0;

// ゲーム終了フラグ
boolean gameEnded = false;
boolean gameWon = false;
// ライフ
int lives = 5;

void setup() {
  size(800, 600);
  
  serial = new Serial(this, "com4", 9600);
  ballX = width / 2;
  ballY = height / 2;
  paddleX = (width / 2 - paddleWidth / 2) + width / 3;
  brickWidth = width / brickCols;
  
  // テクスチャの読み込み
  brickImageFull = loadImage("brickImageFull.png"); // 完全なブロックの画像
  brickImageDamaged = loadImage("brickImageDamaged.png"); // 損傷したブロックの画像
  backgroundImage = loadImage("background.png"); // 背景画像
  
  generateRandomBricks();
  
  ballColor = color(random(255), random(255), random(255)); // 初期のボールの色
}

void draw() {
  background(backgroundImage); // 背景を描画

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

  // ボールの色を更新するか確認
  if (millis() - lastColorChangeTime > 500) { // 0.5秒ごとに色を変更
    ballColor = color(random(255), random(255), random(255));
    lastColorChangeTime = millis();
  }

  // ボールを描画
  fill(ballColor);  
  ellipse(ballX, ballY, ballDiameter, ballDiameter);

  // パドルを描画
  fill(50, 255, 0);  
  rect(paddleX, height - paddleHeight, paddleWidth, paddleHeight);

  // ブロックを描画
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      if (bricks[i][j] > 0) {
        float brickX = j * brickWidth;
        float brickY = brickPositions[i][j];
        if (bricks[i][j] == 2) {
          image(brickImageFull, brickX, brickY, brickWidth, brickHeight); // 完全なブロックを描画
        } else if (bricks[i][j] == 1) {
          image(brickImageDamaged, brickX, brickY, brickWidth, brickHeight); // 損傷したブロックを描画
        }
      } else if (bricks[i][j] == 0 && brickPositions[i][j] < height) {
        // 落下中のブロック
        float brickX = j * brickWidth;
        float brickY = brickPositions[i][j];
        image(brickImageDamaged, brickX, brickY, brickWidth, brickHeight);
        brickPositions[i][j] += brickFallSpeeds[i][j]; // 落下速度を加算
        brickFallSpeeds[i][j] += 0.1; // 重力加速度をシミュレート
      }
    }
  }

  // 残りライフを描画
  fill(255, 0, 0);  
  for (int i = 0; i < lives; i++) {
    ellipse(20 + i * 30, height - 20, 20, 20); // ボールの直径は20、間隔は30
  }

  // ボールの移動と衝突判定
  ballX += ballSpeedX;
  ballY += ballSpeedY;
  
  // 壁との衝突判定
  if (ballX < ballDiameter / 2 || ballX > width - ballDiameter / 2) {
    ballSpeedX *= -1; // 左右の壁で反射
  }
  if (ballY < ballDiameter / 2) {
    ballSpeedY *= -1; // 上端で反射
  }
  if (ballY > height - ballDiameter / 2) {
    // ライフを減少
    lives--;
    if (lives <= 0) {
      gameEnded = true; // ゲーム終了
    } else {
      // ボールの位置と速度をリセット
      ballX = width / 2;
      ballY = height / 2;
      ballSpeedX = 3;
      ballSpeedY = 3;
      paddleSpeed = 10;
      ballDiameter = 20;
      paddleWidth = 150;
      destroyedBricks = 0; // 壊れたブロックの数をリセット
    }
  }
  
  // パドルとの衝突判定
  if (ballY + ballDiameter / 2 > height - paddleHeight && 
      ballX > paddleX && ballX < paddleX + paddleWidth) {
    ballSpeedY *= -1;
  }
  
  // ブロックとの衝突判定
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      if (bricks[i][j] > 0) {
        float brickX = j * brickWidth;
        float brickY = i * brickHeight;
        if (ballX > brickX && ballX < brickX + brickWidth &&
            ballY - ballDiameter / 2 < brickY + brickHeight &&
            ballY + ballDiameter / 2 > brickY) {
          ballSpeedY *= -1;
          bricks[i][j]--; // ブロックの耐久値を減らす
          if (bricks[i][j] == 0) {
            destroyedBricks++; // 壊れたブロックの数を増やす
          }
          
          // ブロックを壊すたびにボールの速度を上げる
          if (destroyedBricks % 3 == 0) { // 3つごとに速度アップ
            ballSpeedX *= 1.1;
            ballSpeedY *= 1.1;
            paddleSpeed *= 1.1;
            ballDiameter *= 1.05;
            paddleWidth *= 1.05; 
          }
        }
      }
    }
  }

  // すべてのブロックが壊されたかを確認
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

  // パドルの移動処理
  // データがあるか確認
  while (serial.available() > 0) {
    String data = serial.readStringUntil('\n'); // 一行のデータを読み込む
    if (data != null) {
      data = trim(data);  // 文字列の前後の空白を削除
      
      println(data);
      
      int value = int(data);  // 整数に変換
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

  // パドルが画面外に出ないように制限
  paddleX = constrain(paddleX, 0, width - paddleWidth);
}

// ランダムなブロック配置を生成
void generateRandomBricks() {
  bricks = new int[brickRows][brickCols];
  brickFallSpeeds = new float[brickRows][brickCols];
  brickPositions = new float[brickRows][brickCols];
  
  for (int i = 0; i < brickRows; i++) {
    for (int j = 0; j < brickCols; j++) {
      float R = random(1);
      if (R > 0.4) { 
        bricks[i][j] = 2;
      } else if (R < 0.2) {
        bricks[i][j] = 1; // 約20%の確率で耐久1のブロック
      } else {
        bricks[i][j] = 0;
      }
      brickFallSpeeds[i][j] = 0; // 初期落下速度
      brickPositions[i][j] = i * brickHeight; // 初期位置
    }
  }
}
