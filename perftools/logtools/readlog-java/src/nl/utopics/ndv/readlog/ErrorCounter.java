package nl.utopics.ndv.readlog;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

public class ErrorCounter {

  private String errorString = null;
  private int counter = 0;

  public ErrorCounter(String aErrorString, int aCounter) {
    errorString = aErrorString;
    counter = aCounter;
  }

  public void inc() {
    counter++;
  }

  public int getCounter() {
    return counter;
  }

  public String toString() {
    return "#" + counter + ": " + errorString;
  }

}