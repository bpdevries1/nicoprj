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

public class LogData {

  /**
   * current level in the logfile. The toplevel (after the first startline) is 0.
   */
  private int currentLevel = -1;

  /**
   * HashMap met info over current ingelezen data: per thread de 'callstack'.
   * De key van de elementen is de thread-id, de waarde dus een Stack met
   * MethodInstance's. Na het totaal inlezen van een call (einde v.e. thread)
   * wordt de hashmap hiervan geschoond. Aan het eind v.d. log moet deze hashmap
   * dus weer leeg zijn. In de praktijk is dit wel lastig, moet de log precies
   * op het eind v.e. call stoppen en nog geen nieuwe call zijn gestart.
   *
   * callstack bevat als eerste element nu een ServiceCallInstance, rest zijn
   * MethodInstance's.
   */
  private HashMap werk = new HashMap();

  /**
   * bevat een lijst van alle toplevel calls (ServiceCallInstance), alle servicecalls dus. Deze staan
   * op volgorde van starten van de call. Deze lijst wordt na het inlezen van
   * de log gebruikt om percentielen te bepalen. Evt. kan later blijken dat dit
   * tussenresultaat niet nodig is, en berekeningen direct kunnen worden gedaan.
   */
  private ArrayList calls = new ArrayList();

  private HashMap serviceCallSummaries = new HashMap();

  /**
   * list with errors that do not belong to one of the service-instances.
   */
  private ArrayList errors = new ArrayList();

  /**
   * 2 vars for identifying last ServiceCallInstance, used for adding error Strings
   */
  private String lastThreadId = null;
  private ServiceCallInstance lastSci = null;

  // public static final String HEADERREGEL = "level\tnaam\ttotaal-calls\tgem.calls\tgem-tijd\tgem.tijd/ caller\tgem-eigentijd\tgem-eigentijd-per-caller\tn/serv.call\ttijd/ serv.call\teigentijd/  serv.call";
  // public static final String HEADERREGEL = "level\tnaam\ttotaal-calls\tgem.calls\tgem-tijd\tgem.tijd/ caller\tgem-eigentijd\tgem-eigentijd-per-caller\tn/serv.call\ttijd/ serv.call\teigentijd/  serv.call\te50\te75\te98\tt50\tt75\tt98";
  public static final String HEADERREGEL = maakHeaderRegel();
  public static final String HEADERREGELNOPERC = "level\tnaam\ttotaal-calls\tgem-tijd\tgem-eigentijd\tn/serv.call\ttijd/ serv.call\teigentijd/  serv.call";

  public static final String maakHeaderRegel() {
    // String result = "level\tnaam\ttotaal-calls\tgem-tijd\tgem-eigentijd\tn/serv.call\ttijd/ serv.call\teigentijd/  serv.call\te50\te75\te98\tt50\tt75\tt98";
    String result = "level\tcomp\tnaam\ttotaal-calls\tgem-tijd\tgem-eigentijd\tn/serv.call\ttijd/ serv.call\teigentijd/  serv.call";
    for (int i = 0; i < MethodSummary.N_PERC; i++) {
      result = result + "\te" + MethodSummary.PERC[i];
    }
    for (int i = 0; i < MethodSummary.N_PERC; i++) {
      result = result + "\tt" + MethodSummary.PERC[i];
    }
    return result;
  }
  /**
   * constructor, init hashmaps etc.
   */
  public LogData() {
  }

  // public void putLine(LineStruct ls, int aLinenumber) {
  public void putLine(LineStruct ls) {
    MethodInstance mi = null;
    ServiceCallInstance sci = null;
    boolean newcall = false;

//    if (!ls.methode.equals(HANDLEXML)) {
      Stack callstack = (Stack)werk.get(ls.thread); // kan null opleveren bij nieuwe thread
      // if (ls.isStartRegel) {
      if (ls.soortRegel == LineStruct.LS_START) {
        if (callstack == null) {
          // nieuwe call, zet in lijst en in hashmap
          newcall = true;
          callstack = new Stack();
          werk.put(ls.thread, callstack);
        }
        // startregel, dus aanmaken nieuwe MethodInstance.
        // eigenlijk zowel thread als level niet interessant hier.
        // mi = new MethodInstance(ls.methode, ls.thread, -1, ls.datumTijd);
        mi = new MethodInstance(ls.componentnaam, ls.methode, -1, ls.linenumber);
        if (newcall) {
          // calls.add(mi);
          sci = new ServiceCallInstance(ls.thread, ls.datumTijd);
          calls.add(sci);
          callstack.push(sci);
          sci.setTopMethodInstance(mi);
        } else { // bestaande servicecall
          // voeg subcall toe aan parent-lijst.
          ((MethodInstance)callstack.peek()).addSubCall(mi);
        }
        callstack.push(mi);
        WoonTest.checkSetName(callstack);
      } else if (ls.soortRegel == LineStruct.LS_EIND) { // stopregel
        // callstack moet hier al bestaan. Evt. niet bij start v.e. log, waarbij
        // info over een niet volledige call-log voorkomt.
        if (callstack == null) {
          // er klopt iets niet met deze call, niet verder verwerken, stukkie printen.
          System.err.print("Fout bij einde call, callstack is null. ");
          ls.print();
        } else {
          mi = (MethodInstance)callstack.pop();
          // check of teksten overeenkomen, anders warning geven.
          if ((!logregelsGelijk(mi.getNaam(), ls.methode)) && (!WoonTest.isLogPaar(mi.getNaam(), ls.methode))) {
             System.err.println("Logteksten komen niet overeen,  start = " + mi.getNaam() +
                              ", stop = " + ls.methode + ".");
             // dan ook de stop-tekst in de MethodInstance zetten
             mi.setStopNaam(ls.methode);
          }
          mi.setStopregel(ls.linenumber);
          mi.setTijd(ls.tijd);
          mi.berekenTijden();
          if (callstack.size() == 1) {
            // nog 1 element, is service-call, dus voltooid, haal uit werklijst
            sci = (ServiceCallInstance)callstack.pop();
            sci.setEindtijd(ls.datumTijd);
            werk.remove(ls.thread);

            // set last SCI
            lastThreadId = ls.thread;
            lastSci = sci;
          }
        }
      } else if (ls.soortRegel == LineStruct.LS_ERROR) {
        // ServiceCallInstance is bottom van de stack
        if ((callstack == null) || (callstack.size() == 0)) {
          System.err.println("Found ERROR, but no current service: " + ls);
          // error zou bij laatst afgeronde kunnen horen, check op thread-id
          if (ls.thread.equals(lastThreadId)) {
            lastSci.addError(ls);
          } else {
            // anders toevoegen aan algemene lijst.
            errors.add(ls);
          }
        } else {
          sci = (ServiceCallInstance)callstack.elementAt(0);
          sci.addError(ls);
        }
      } else {
        throw new RuntimeException("foute soort regel: " + ls.soortRegel);
      }


//    } // endif handleXML
  }


  /**
   * print an indented line, used for testing.
   */
  private void printline(int level, LineStruct ls) {
    System.out.print(level + ". ");
    for (int i = 0; i < level; i++) {
      System.out.print("  ");
    }
    System.out.print(ls.methode);
    if (ls.soortRegel == LineStruct.LS_START) {
      System.out.println("");
    } else if (ls.soortRegel == LineStruct.LS_EIND) {
      System.out.println(" - " + ls.tijd);
    }
  }
  /**
   * some postprocessing on the structure, calculate percentiles etc.
   */
  public void handleStructs(String outputFilename, boolean showPercentiles)
  throws FileNotFoundException {
    // voorlopig even wat printen, later echt wat mee doen.
    MethodInstance mi = null;
    ServiceCallInstance sci = null;

/** @todo niet voltooide calls verwijderen, want vertroebelen totaalbeeld. */

    // BufferedWriter out = new BufferedWriter(new FileWriter("d:/temp/readlog.out"));
    // PrintStream out = new PrintStream(new BufferedOutputStream(new FileOutputStream("d:/temp/readlog.out")));
    PrintStream out = new PrintStream(new BufferedOutputStream(new FileOutputStream(outputFilename)));

    // kijken of er nog wat in 'werk' zit, zou leeg moeten zijn.
    out.println("Nog aanwezige calls in 'werk'");
    out.println("-----------------------------");
    Iterator it = werk.keySet().iterator();
    String thread = null;
    Stack stack = null;
    while (it.hasNext()) {
      thread = (String)it.next();
      stack = (Stack)werk.get(thread);
      // bepaal toplevel method.
      mi = null;
      // while (!stack.empty()) {
      while (stack.size() > 1) {
        mi = (MethodInstance)stack.pop();
      }
      // if (mi != null) {
      if (stack.size() == 1) {
        // laatste element is ServiceCallInstance
        sci = (ServiceCallInstance)stack.pop();
        sci.print(out, false); // sowieso printen
      }
    }

    out.println("-------------------------");
    out.println("Volledige lijst van calls");
    out.println("-------------------------");
    // printen van volledige lijst.
    it = calls.iterator();
    while (it.hasNext()) {
      //mi = (MethodInstance)it.next();
      //mi.print(out, true); // alleen voltooide
      sci = (ServiceCallInstance)it.next();
      sci.print(out, true); // alleen voltooide
    }

    // print ´global´ errors
    printErrors(out);

    out.println("-------------------------");
    out.println("Summary van calls");
    out.println("-------------------------");
    // out.println("level\tnaam\ttotaal-calls\tgem.calls\tgem-tijd\tgem.tijd/ caller\tgem-eigentijd\tgem-eigentijd-per-caller\tn/serv.call\ttijd/ serv.call\teigentijd/  serv.call");
    if (showPercentiles) {
      out.println(HEADERREGEL);
    } else {
      out.println(HEADERREGELNOPERC);
    }


/** @todo Nu alles op 1 hoop gooien, niet meer met sci. Dan te bepalen:
 *  tijden, #gem per caller, tijdtotaalgem per caller; alles ook in percentielen.
 *  -> grotendeels done; om single-level te maken, moeten tijden gedeeld worden
 *  door aantal service-calls, niet aantal parent-calls; zo worden eigenTijden
 *  significant, en optellen leidt dan tot totale gemiddelde tijd per service-call. */

/** @todo Hierna alles op 1 niveau, en tijden tov. servicecall aangeven. Hierbij dan
 *  focussen op de eigenTijden, niet incl. subtijden. */

    // nu het eigenlijke processing-werk per service call instance.


    ServiceCallSummary scs = null;
    it = calls.iterator();
    while (it.hasNext()) {
      //mi = (MethodInstance)it.next();
      //mi.print(out, true); // alleen voltooide
      sci = (ServiceCallInstance)it.next();
      scs = this.getServiceCallSummary(sci.getTopMethodInstance().getComponentnaam(), sci.getTopMethodInstance().getNaam());
      scs.summarize(sci);
      // sci.summarize();
      // sci.printSummary(out);
    }

    // sorteer items op naam
    // hierna scs's nog printen
    it = serviceCallSummaries.values().iterator();
    ArrayList summaries = new ArrayList();
    while (it.hasNext()) {
      summaries.add(it.next());
    }
    Collections.sort(summaries, new ServiceCallSummaryComparator());

    // it = serviceCallSummaries.keySet().iterator();
    it = summaries.iterator();
    while (it.hasNext()) {
      // scs = (ServiceCallSummary)serviceCallSummaries.get(it.next());
      scs = (ServiceCallSummary)it.next();
      scs.printSummary(out, showPercentiles);
    }

  }

  /**
   * print the structure to stdout.
   * maybe later to database, XML or HTML.
   */
/*
  public void printStructs() {

  }
*/

  /**
   * controleer of logregels voor start en stop gelijk zijn, evt.
   * start: of stop: teksten negeren.
   */
  private boolean logregelsGelijk(String start, String stop) {
    int p = start.indexOf(":");
    if (p != -1) {
      start = start.substring(p + 2);
    }
    p = start.indexOf("start");
    if (0 == p) {
      start = start.substring(p + 6);
    }

    p = stop.indexOf(":");
    if (p != -1) {
      stop = stop.substring(p + 2);
    }

    p = stop.indexOf("stop");
    if (0 == p) {
      stop = stop.substring(p + 5);
    }

    return (start.equals(stop));
  }

  private void printErrors(PrintStream out) {
    if (errors.size() > 0) {
      out.println("\nGlobal Errors:");
      Iterator it = errors.iterator();
      while (it.hasNext()) {
        out.println((LineStruct)it.next());
      }
      out.println();
    }

  }


///////////////////////////////////////////////////
// methods for hashmap of ServiceCallSummary's
///////////////////////////////////////////////////

  /**
   * find the subcall with aNaam or create a new one.
   */
  public ServiceCallSummary getServiceCallSummary(String aComponentnaam, String aNaam) {
    ServiceCallSummary result = (ServiceCallSummary)serviceCallSummaries.get(aNaam);
    if (result == null) {
      result = new ServiceCallSummary(aComponentnaam, aNaam);
      serviceCallSummaries.put(aNaam, result);
    }
    return result;
  }

}