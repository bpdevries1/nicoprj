import java.io.*;
import lejos.nxt.*;
import lejos.util.*;

// import lejos.robotics.navigation.DifferentialPilot;

public class Logger {
  
  PrintStream ps = null;
  FileOutputStream fos = null;
  Stopwatch sw  = null;
  
  public Logger(String filename) 
  throws FileNotFoundException, IOException {
    // ps = new PrintStream(new FileOutputStream(new File(filename)));
    File f = new File(filename);
    fos = new FileOutputStream(f);
    ps = new PrintStream(fos);
    ps.println("Logging started");
    ps.flush();
    
    sw = new Stopwatch();
    sw.reset();    
  }
  
  public void close() 
  throws IOException {
    ps.flush();
    ps.close();
    fos.flush();
    fos.close();
  }
  
  public void log(String s) {
    ps.println(sw.elapsed() + ": " + s);
    ps.flush();
  }
}


