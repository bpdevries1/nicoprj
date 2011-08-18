import java.io.*;

import lejos.nxt.*;
import lejos.util.*;
import lejos.robotics.navigation.DifferentialPilot;

public class ExploroBot {

  // public static double TURN_FACTOR = 7.3888;
  // public static double TURN_FACTOR = 7.5;
  DifferentialPilot pilot;
  UltrasonicSensor sonar;
  double trackWidth;
  Logger log;
  
  public static void main (String[] args) 
  throws FileNotFoundException, IOException, InterruptedException {
    ExploroBot bot = new ExploroBot();
    bot.init();
    bot.showMenu();
  }
  private static final double TRACKWIDTH_ORIG = 15.0;
  
  private void init() 
  throws FileNotFoundException, IOException {
		log = new Logger("explo.log");
		log.log("Started!");
    SensorPort sp = SensorPort.getInstance(3); // port 4 - 1
    sonar = new UltrasonicSensor(sp);
    sonar.continuous();
    // trackWidth = 16.2f;
    // trackWidth = 10.0; // a bit smaller than the real thing, check more than 1 virtual 360 turn. Outer while in calibrate().
    // trackWidth = TRACKWIDTH_ORIG; // 7-7-2011 real width now, check what this gives. 
    initPilot(TRACKWIDTH_ORIG);    
  }
  
  private void initPilot(double aTrackWidth) {
    trackWidth = aTrackWidth;
    // pilot = new DifferentialPilot(4.3f, trackWidth, Motor.C, Motor.B);
    pilot = new DifferentialPilot(6.3f, trackWidth, Motor.C, Motor.B); // 7-7-2011 have bigger wheels now.
  }
  
  public void showMenu() 
  throws IOException, InterruptedException {
    String[] viewItems = {"Calibrate", "Turn360", "Run", "Reset trackwidth", "Exit"};
		TextMenu main = new TextMenu(viewItems, 1, "ExploroBot");
		for(;;) {
			LCD.clear();

      int selection = main.select();
      if (selection == -1 || selection == 4) {
        LCD.clear();
        LCD.drawString("Finished",3,4);
        LCD.refresh();	
        log.log("Closing app");
        log.close();
        Thread.sleep(5000);
        return;
      }
      if (selection == 0) {
        calibrate();
      }
      if (selection == 1) {
        turn360();
      }
      if (selection == 2) {
        run();
      }
      if (selection == 3) {
        resetTrackWidth(); 
      }
    }
  }

  
  /** calibrate the motors with the wheel size and trackWidth, so 90 degrees is really 90 degrees.
   * strategy: 
   * pre: object is placed to that turning left, it reached the closest object first.
   * keep a running median value for the last 5 measurements.
   * if the median is bigger than the last time, a minimum has been reached: note distance, degrees and time.
   * continue until a new minimum is reached.
   * if this minimum is close enough (within 5 cm) of the old minimum, we have made a full 360 degrees turn
   * if not, another (local) minimum has been reached, continue.
   * not the distance, degrees and time again.
   * calculate and set the new trackwidth
   * time is handled by logger, initially not used in calculation.
  */   
  private void calibrate() 
  throws InterruptedException {
    pilot.reset();
    // pilot.setRotateSpeed(45);
    pilot.setRotateSpeed(15);
    int state = 0; // 0: started, 1: found first minimum, and distance increasing, 2: distance decreasing, 3: finished
    float angle1 = 0, // angle at first (absolute) minimum 
          angle2 = 0, // angle at second absolute minum
          angle = 0, // angle difference.
          rounds = 0, // rounds turned (increase if current angle is smaller than previous) 
          prev_angle = -1; // previous angle
    int min_avg_distance = -1, // minimum absolute distance
        distance = -1,
        curr_avg_distance = -1,
        prev_avg_distance = -1; // current distance
        //ar_distance[NDISTANCES], // array of previous distances, to calculate median.
        //ptr_ar_dist = -1; // 'pointer' to last distance inserted.
    int tacho = -1, prev_tacho = -1, tacho_rounds = 0; // tacho count of Motor.B (right wheel) which supposedly runs forward when the machine is turning left.
    Distances distances = new Distances(sonar.getDistance());
    prev_avg_distance = distances.average();
    LCD.clear();
    Thread.sleep(3000); // wait a bit after start button pressed.
    System.out.println("State = 0");
    log.log("Calibration started.");    
    pilot.rotate(540, true); // 1.5 rounds only one rotate command, because it resets the angle counter
    
    while ((state < 3) && (pilot.isMoving())) {
      distance = sonar.getDistance();
      angle = pilot.getMovement().getAngleTurned();
      distances.add(distance);
      curr_avg_distance = distances.average();
      log.log("dist: " + distance + ", avg: " + curr_avg_distance + ", angle: " + angle);
      if (angle < prev_angle - 300) {
        rounds++;
        log.log("Rounds: " + rounds); 
      }
      tacho = Motor.B.getTachoCount();
      if (tacho < prev_tacho - 300) {
         tacho_rounds++;
      }
      prev_tacho = tacho;
      log.log("tacho.B: " + tacho + ", tacho.C: " + Motor.C.getTachoCount() + ", rounds: " + tacho_rounds);
      
      if (curr_avg_distance > prev_avg_distance) {
        // we have found a minimum
        if (state == 0) {
          min_avg_distance = prev_avg_distance;
          angle1 = angle;
          state = newState(1); 
        } else if (state == 1) {
          // newsState(2); // distance increasing
          // nothing, still increasing.
        } else {  
          // state == 2, distance decreasing
          if (Math.abs(min_avg_distance - prev_avg_distance) < 5) {
            // difference is smaller than 5 centimeters, so this is the same absolute minimum
            angle2 = angle;
            state = newState(3);
          } else {
            state = newState(1); // distance increasing 
          }
        }
      } else if (curr_avg_distance < prev_avg_distance) {
        if (state == 1) {
          state = newState(2);
        } else {
          // state == 0 or 2, stay the same.
        }
      }
      prev_avg_distance = curr_avg_distance;
      prev_angle = angle;  
      Thread.sleep(100);
    }
    pilot.stop();
    log.log("Calibration finished");
    log.log("angle1: " + angle1);
    log.log("angle2: " + angle2);
    log.log("rounds: " + rounds);
    float angleTotal = rounds * 360 + angle2 - angle1;
    double new_trackWidth = trackWidth * (angleTotal / 360.0);
    System.out.println("angle total: " + angleTotal);
    log.log("angle total: " + angleTotal);
    System.out.println("new trackWidth: " + new_trackWidth);
    log.log("new trackWidth: " + new_trackWidth);
    initPilot(new_trackWidth);
    System.out.println("Press a key...");
    Button.waitForPress();
  }

  private void resetTrackWidth () {
    initPilot(TRACKWIDTH_ORIG);
  }
  
  private int newState(int state) 
  throws InterruptedException {
    log.log("State = " + state);
    System.out.println("State = " + state);
    Sound.beep();
    // Sound.pause(100);
    // Thread.sleep(100);
    return state; 
  }
  
  private void run() {
    for (int i=0; i<3; i++) {
      // runMotorTurn(Motor.C, Motor.B, 90);  
      runMotorTurn(90);
    }

    // wait 10 seconds
    Stopwatch stopwatch = new Stopwatch();
    stopwatch.reset();
    while (stopwatch.elapsed() < 10000) {}
    
    // turn left once more
    turn(90);
    
    // and go back: the right turn at the end is not strictly necessarry
    for (int i=0; i<3; i++) {
      // runMotorTurn(Motor.C, Motor.B, -90);
      runMotorTurn(-90);
    }
    
  }

  private void turn360() 
  throws InterruptedException {
    // vraag of deze echt 360 graden draait...
    log.log("Turn 360 started (2)");
    pilot.reset();
    pilot.setRotateSpeed(45);
    for (int i=0; i<4; i++) {
      log.log("Start angle: " + pilot.getMovement().getAngleTurned());
      log.log("start tacho.B: " + Motor.B.getTachoCount() + ", tacho.C: " + Motor.C.getTachoCount());
      turn2(90); 
      // en nu hier een tight loop met distance meten en thread.sleep.
      while (pilot.isMoving()) {
        // log.log("current tacho.B: " + Motor.B.getTachoCount() + ", tacho.C: " + Motor.C.getTachoCount());
        // log.log("sonar distance: " + sonar.getDistance());
        Thread.sleep(100);
      }
      
      log.log("End angle: " + pilot.getMovement().getAngleTurned());
      log.log("end tacho.B: " + Motor.B.getTachoCount() + ", tacho.C: " + Motor.C.getTachoCount());
    }
    log.log("Turn 360 finished");
  }
  
  private void turn2(int degreesTurn) {
    // pilot.reset();
    // pilot.setRotateSpeed(45);
    pilot.rotate(degreesTurn, true); 
  }

  private void turn(int degreesTurn) {
    // pilot.reset();
    // pilot.setRotateSpeed(45);
    pilot.rotate(degreesTurn); 
  }
  
  // turn left is negative degrees, turn right is positive.
  private void runMotorTurn(int degreesTurn) {

    pilot.setTravelSpeed(20.0);
    pilot.forward();
    
    while (sonar.getDistance() > 25) {}

    pilot.stop();
    
    turn(degreesTurn);
  }

  
}
