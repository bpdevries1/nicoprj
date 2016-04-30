import lejos.nxt.*;
      
public class Motor1 {
  public static void main (String[] args) {
    Motor.A.forward();
    LCD.drawString("FORWARD", 0, 0);
    Button.waitForPress();
    Motor.A.backward();
    LCD.drawString("BACKWARD", 0, 1);
    Button.waitForPress();
    Motor.A.forward();
    LCD.drawString("FORWARD", 0, 2);
    Button.waitForPress();
    Motor.A.stop();
  }
}
