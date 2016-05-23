package nl.utopics.ndv.readlog;

import java.util.*;
import java.io.*;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

public class RejectList {

  private ArrayList list = new ArrayList();

  /**
   * @pre: rejectFilename can be null.
   */
  public RejectList(String rejectFilename) throws FileNotFoundException, IOException {
    if (rejectFilename != null) {
      String regel = null;
      BufferedReader in = new BufferedReader(new FileReader(rejectFilename));
      while ((regel = in.readLine()) != null) {
        if ((regel.length() > 0) && (regel.charAt(0) != '#')) {
          list.add(regel);
        }
      }
      in.close();
    }
  }

  public boolean isRejected(String line) {
    boolean found = false;
    String reject = null;
    Iterator it = list.iterator();
    while (it.hasNext()) {
      reject = (String)it.next();
      if (line.indexOf(reject) > -1) {
        found = true;
      }
    }
    return found;
  }

}