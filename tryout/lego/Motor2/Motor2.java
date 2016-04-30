import lejos.nxt.*;
      
public class Motor2 {
  public static void main (String[] args) {
    motorRound(Motor.A);
    Motor.A.setSpeed(720);
    motorRound(Motor.A);
  }
  
  private static void motorRound(NXTRegulatedMotor m) {
    m.resetTachoCount();
    m.forward();
    while (m.getTachoCount() < 360) {}
    m.stop();
    //m.flt();
    while (m.getRotationSpeed() != 0) {}
    LCD.drawInt(m.getTachoCount(), 0, 0);
    LCD.drawInt(124, 0, 1);
    Button.waitForPress();
  }
  
}
