import lejos.nxt.*;
      
public class HelloWorld {
  public static void main (String[] args) {
    System.out.println("Hello World");
    Button.waitForPress();
    System.out.println("Hello Nico!");
    Button.waitForPress();
  }
}
