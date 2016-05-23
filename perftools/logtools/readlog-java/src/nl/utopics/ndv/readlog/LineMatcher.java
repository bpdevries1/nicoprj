package nl.utopics.ndv.readlog;

import org.apache.regexp.*;
import java.io.*;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

public class LineMatcher {

// [2002-03-28 10:04:08,283] PERF  [Thread-47] nl.achmea.aol.common.messagebroker.MQConnection# MQ: Engine_responsetime:
// [2002-03-28 10:04:08,961] PERF  [Thread-47] nl.achmea.aol.common.messagebroker.MQConnection# MQ: Engine_responsetime: : 678 ms

  /**
   * regexp voor PERF logstring met (stopregel) of zonder (startregel) milliseconden.
   * paran 1: datum/tijd
   * paran 2: thread
   * param 3: package + class
   * paran 4: logstring
   * paran 5: null bij start, not null bij eindregel
   * paran 6: aantal milliseconden bij stopregel.
   */
  // private String strRegexp = "^\\[[^\\]]+\\] PERF  \\[([^\\]]+)\\] [^#]+# (.*?)(: ([0-9]+) ms)?$";
  private String strRegexpPerf = "^\\[([^\\]]+)\\] PERF  \\[([^\\]]+)\\] ([^#]+)# (.*?)(: (-?[0-9]+) ms)?$";

  /**
   * regexp voor ERROR logstring.
   * paran 1: datum/tijd
   * paran 2: thread
   * param 3: package + class
   * paran 4: logstring
   * paran 5: null bij start, not null bij eindregel
   * paran 6: aantal milliseconden bij stopregel.
   */
  private String strRegexpError = "^\\[([^\\]]+)\\] ERROR \\[([^\\]]+)\\] ([^#]+)# (.*?)(: (-?[0-9]+) ms)?$";

  // tijdelijk ook met stukje tussen blokhaken aan het einde.
  // private String strRegexp = "^\\[([^\\]]+)\\] PERF  \\[([^\\]]+)\\] [^#]+# (.*?)(: ([0-9]+) ms)?( \\[.*?\\])?$";

  // [2002-04-19 16:15:09,120] PERF  [ExecuteThread: '13' for queue: 'default']: stop createOvereenkomst: -1 ms [createOvereenkomst;?]
  // private String strRegexp = "^\\[([^\\]]+)\\] PERF  \\[([^\\]]+)\\]: (.*?)(: ([0-9]+) ms)? \\[.*?\\]$";

  /**
   * voorgecompileerde regexp voor Perf.
   */
  private RE rePerf = null;

  /**
   * voorgecompileerde regexp voor Error.
   */
  private RE reError = null;

  /**
   * current (5-4-2002) error in logfile: unmatched PERF-lines.
   */

/*
  private String reject = "nl.achmea.aol.common.servicelistener.services.AOLServiceExecutor# Starting to send message to Service Provider Bean : Engine Header";
  // private String reject2 = "nl.achmea.aol.basisproduct.BasisproductComponentBean# getParent";
  private String reject2 = "22nl.achmea.aol.basisproduct.BasisproductComponentBean# retrieveProduct";
  // private String reject3 = "nl.achmea.aol.basisproduct.BasisproductComponentBean# retrieveProduct: 0 ms";
  // private String reject2 = "abcd";
  private String reject3 = "abcd";
*/

  /**
   * handles lines to reject, from (wrt. logging) bad components.
   */
  private RejectList rejectList = null;

  public LineMatcher(String rejectFilename) throws RESyntaxException, IOException, FileNotFoundException {
    // System.err.println("Regexp perf: " + strRegexpPerf);
    rePerf = new RE(strRegexpPerf);

    reError = new RE(strRegexpError);

    rejectList = new RejectList(rejectFilename);
  }

  public LineStruct parseLine(String line, int aLinenumber) {
    LineStruct res = null;

//    if ((line.indexOf(reject) == -1) && (line.indexOf(reject2) == -1) &&
//        (line.indexOf(reject3) == -1)) {
    if (!rejectList.isRejected(line)) {

      boolean gevonden = rePerf.match(line);

      // voorlopig hardcoded check op ovk.
/*
      if (gevonden) {
        // if (line.indexOf("nl.achmea.aol.ovk") == -1) {
        if (line.indexOf("nl.achmea.aol.basisproduct") > -1) {
          gevonden = false;
        }
      }
*/
      if (gevonden) {
        // check if 'tijd' is filled
        if (rePerf.getParen(5) == null) { // startregel
          // res = new LineStruct(rePerf.getParen(1), rePerf.getParen(2), rePerf.getParen(4), true, 0);
          res = new LineStruct(rePerf.getParen(1), rePerf.getParen(2), rePerf.getParen(3),
                            rePerf.getParen(4), LineStruct.LS_START, 0, aLinenumber);
        } else { // stopregel
          res = new LineStruct(rePerf.getParen(1), rePerf.getParen(2), rePerf.getParen(3),
                               rePerf.getParen(4), LineStruct.LS_EIND,
                               Integer.parseInt(rePerf.getParen(6)), aLinenumber);

        }
/*
        System.out.println("string : " + line);
        System.out.println("paren 0: " + rePerf.getParen(0) + "***");
        System.out.println("paren 1: " + rePerf.getParen(1) + "***");
        System.out.println("paren 2: " + rePerf.getParen(2) + "***");
        System.out.println("paren 3: " + rePerf.getParen(3) + "***");
        System.out.println("paren 4: " + rePerf.getParen(4) + "***");
        System.out.println("paren 5: " + rePerf.getParen(5) + "***");
        System.out.println("paren 6: " + rePerf.getParen(6) + "***");
        System.out.println("paren 7: " + rePerf.getParen(7) + "***");
*/
      } else if (reError.match(line)) { // error-regel.
          res = new LineStruct(reError.getParen(1), reError.getParen(2), reError.getParen(3),
             reError.getParen(4), LineStruct.LS_ERROR, 0, aLinenumber);
      }
    }
    return res;
  }

}