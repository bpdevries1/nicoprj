package nl.utopics.ndv.readlog;

import java.io.*;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

/** @todo handling van foute logs, of logs die niet precies alle info van
 *  een call bevatten. */

/** @todo checken op ERROR, callstack dan in de war, sowieso wel handig... */


public class Main {

  public Main() {
  }
  public static void main(String[] args) {
    if (args.length < 2) {
      System.err.println("Syntax: readlog [-noperc] <inputfile> <outputfile> [<rejectfile>]");
      System.exit(1);
    }
    Main main = new Main();
    int index = 0;
    boolean showPercentiles = true;
    if (args[0].equals("-noperc")) {
      showPercentiles = false;
      index = 1;
    }

    if (args.length == (2 + index)) {
      main.run(args[0 + index], args[1 + index], null, showPercentiles);
    } else {
      main.run(args[0 + index], args[1 + index], args[2 + index], showPercentiles);
    }
  }

  /**
   * hoofd methode.
   */
  public void run(String inputFilename, String outputFilename, String rejectFilename, boolean showPercentiles) {
    try {
      System.err.println("input: " + inputFilename);
      System.err.println("output: " + outputFilename);
      System.err.println("reject: " + rejectFilename);
      System.err.println("show Percentiles: " + showPercentiles);

      String logRegel = null;
      // String aFilename = "D:\\CB\\perf\\readlog\\logs\\log4j.log";
      // String aFilename = "d:\\cb\\perfmeetmod\\logs\\test1voll.log";
      // String aFilename = "d:\\cb\\perfmeetmod\\logs\\test2voll.log";
      // String aFilename = "d:\\cb\\perfmeetmod\\logs\\test3voll.log";
      LineStruct ls = null;
      LineMatcher matcher = new LineMatcher(rejectFilename);

      LogData logData = new LogData(); // init hashmaps etc.

      // open input file
      // BufferedReader in = new BufferedReader(new FileReader(aFilename));
      BufferedReader in = new BufferedReader(new FileReader(inputFilename));
      int linenumber = 0;
      while ((logRegel = in.readLine()) != null) {
        linenumber++;
        ls = matcher.parseLine(logRegel, linenumber);
        if (ls != null) {
          // ls.print(); // for debugging.
          // logData.putLine(ls, linenumber);
          logData.putLine(ls);
        }
      } // while

      in.close();

      // handle datastructure (calculate percentiles)
      logData.handleStructs(outputFilename, showPercentiles);

      // output to stdout. (later to db or (XML) file)
      // logData.printStructs();
    } catch (Exception e) {
      e.printStackTrace();
    }
  }

}