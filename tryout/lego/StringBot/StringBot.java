import java.io.*;

import lejos.nxt.*;
import lejos.util.*;
import lejos.robotics.navigation.DifferentialPilot;

public class StringBot {

  // public static double TURN_FACTOR = 7.3888;
  // public static double TURN_FACTOR = 7.5;
  DifferentialPilot pilot;
  UltrasonicSensor sonar;
  Logger log;
  
  public static void main (String[] args) 
  throws FileNotFoundException, IOException, InterruptedException {
    StringBot bot = new StringBot();
    bot.init();
    bot.showMenu();
  }
  
  private void init() 
  throws FileNotFoundException, IOException {
		log = new Logger("string.log");
		log.log("Started!");
    SensorPort sp = SensorPort.getInstance(0); // port 4 - 1
    sonar = new UltrasonicSensor(sp);
    sonar.continuous();
    // trackWidth = 16.2f;
    // trackWidth = 10.0; // a bit smaller than the real thing, check more than 1 virtual 360 turn. Outer while in calibrate().
    // trackWidth = TRACKWIDTH_ORIG; // 7-7-2011 real width now, check what this gives. 
    initPilot();    
  }
  
  private void initPilot() {
    // pilot = new DifferentialPilot(4.3f, trackWidth, Motor.C, Motor.B);
    // pilot = new DifferentialPilot(4.3f, 15f, Motor.C, Motor.B, true); // turning is forbidden here! reverse here.
    pilot = new DifferentialPilot(4.3f, 15f, Motor.C, Motor.B, false); // string on top, so other way, so forward again.
  }
  
  public void showMenu() 
  throws IOException, InterruptedException {
    String[] viewItems = {"Deliver", "Test drop", "Run fast", "Run slow", "Exit"};
		TextMenu main = new TextMenu(viewItems, 1, "StringBot");
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
        deliver();
      }
      if (selection == 1) {
        testDrop();
      }
      if (selection == 2) {
        runFast();
      }
      if (selection == 3) {
        runSlow(); 
      }
    }
  }

  public void deliver() 
  throws InterruptedException {
    log.log("deliver: Start");
    Thread.sleep(3000);
    pilot.reset();
    pilot.setTravelSpeed(15);
    pilot.forward();
    while (sonar.getDistance() > 60) {
      Thread.sleep(100); 
    }
    log.log("Dist traveled1: " + pilot.getMovement().getDistanceTraveled());
    float dist = pilot.getMovement().getDistanceTraveled();
    pilot.setTravelSpeed(5);
    pilot.forward();
    while (sonar.getDistance() > 35) {
      Thread.sleep(100); 
    }
    log.log("Dist traveled2: " + pilot.getMovement().getDistanceTraveled());
    pilot.stop();
    dist += pilot.getMovement().getDistanceTraveled();
    log.log("Dist traveled3: " + dist);
    log.log("C tacho: " + Motor.C.getTachoCount());
    log.log("B tacho: " + Motor.B.getTachoCount());
    
    Thread.sleep(3000);
    dropCoin();
    pilot.setTravelSpeed(20);
    pilot.travel(-dist);    

    log.log("deliver: Finished");
  }
  
  public void testDrop() 
  throws InterruptedException {
    // Motor.A.setPower(25);
    log.log("testDrop: Start");
    Thread.sleep(3000);
    log.log("Slept 3 seconds");
    log.log("Distance: " + sonar.getDistance());
    Motor.A.setSpeed(360 / 8); // kwartslag in 2 seconden
    Motor.A.rotate(-90);
    Thread.sleep(1000);
    Motor.A.rotate(90);
    log.log("Distance: " + sonar.getDistance());
    log.log("testDrop: Finished");
  }

  public void dropCoin() 
  throws InterruptedException {
    // Motor.A.setPower(25);
    log.log("dropCoin: Start");
    log.log("Slept 3 seconds");
    log.log("Distance: " + sonar.getDistance());
    Motor.A.setSpeed(360 / 8); // kwartslag in 2 seconden
    Motor.A.rotate(-90);
    Thread.sleep(1000);
    Motor.A.rotate(90);
    log.log("Distance: " + sonar.getDistance());
    log.log("dropCoin: Finished");
  }

  public void runFast() 
  throws InterruptedException {
    log.log("runFast: Start");
    Thread.sleep(3000);
    log.log("Slept 3 seconds");
    log.log("Distance: " + sonar.getDistance());
    pilot.setTravelSpeed(20);
    pilot.travel(100); // 1 meter
    pilot.stop();    
    log.log("Distance: " + sonar.getDistance());
    log.log("runFast: Finished");
  }

  public void runSlow() 
  throws InterruptedException {
    log.log("runSlow: Start");
    Thread.sleep(3000);
    log.log("Slept 3 seconds");
    log.log("Distance: " + sonar.getDistance());
    pilot.setTravelSpeed(5);    
    pilot.travel(20); // 1 meter
    pilot.stop();    
    log.log("Distance: " + sonar.getDistance());
    log.log("runSlow: Finished");
    
  }
  
}
