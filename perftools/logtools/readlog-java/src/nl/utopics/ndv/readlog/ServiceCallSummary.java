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

public class ServiceCallSummary {

  /**
   * naam
   */
  private String naam = null;

  /**
   * reference to toplevel method-summary.
   */
  private MethodSummary msTop = null;

  /**
   * hashmap with errors and counters
   */
  private HashMap errors = new HashMap();

  /**
   * constructor
   */
  public ServiceCallSummary(String aComponentnaam, String aNaam) {
    naam = aNaam;
    msTop = new MethodSummary(aComponentnaam, aNaam);
  }

  public void summarize(ServiceCallInstance sci) {
    if (sci.getEindtijd() != null) {
      // msTop = new MethodSummary(miTop.getNaam());
      // msTop al eerder aangemaakt.
      summarize(sci.getTopMethodInstance(), this.msTop);
      addErrors(sci);
    }
  }

  /**
   * summarize for a single method instance to a single method summary
   * @pre: both params are not null.
   */
  private void summarize(MethodInstance mi, MethodSummary ms) {
    ms.addMethodInstance(mi);
    Iterator it = mi.getSubCalls().iterator();
    MethodInstance miSub = null;
    MethodSummary msSub = null;
    while (it.hasNext()) {
      miSub = (MethodInstance)it.next();
      msSub = ms.getSub(miSub.getComponentnaam(), miSub.getNaam());

      summarize(miSub, msSub);

      // evt. na subcalls nog bepaalde berekeningen doen.
    }
  }

  /**
   * add errors from instance to summary
   */
  private void addErrors(ServiceCallInstance sci) {
    Iterator it = sci.getErrors().iterator();
    while (it.hasNext()) {
      addError((LineStruct)it.next());
    }
  }

  private void addError(LineStruct ls) {
    ErrorCounter ec = (ErrorCounter)errors.get(ls.methode);
    if (ec == null) {
      ec = new ErrorCounter(ls.methode, 1);
      errors.put(ls.methode, ec);
    } else {
      ec.inc();
    }
  }

  /**
   * print the summary, for now only number of calls in hierarchical structure.
   */

  public void printSummary(PrintStream out, boolean showPercentiles) {
//    if (this.eindtijd != null) {
      out.println("");
      // out.println("Summary: " + this.starttijd + " -> " + this.eindtijd + " (" + this.thread + ")");
      out.println("Summary: " + this.naam);
      out.println(LogData.HEADERREGEL);
      msTop.print(out, 0, 1, msTop.getNInstances(), showPercentiles);
      printErrors(out);
      out.println("---");
      out.flush();
//    }

  }

  private void printErrors(PrintStream out) {
    if (errors.size() > 0) {
      out.println("\nErrors:");
      Iterator it = errors.values().iterator();
      while (it.hasNext()) {
        ErrorCounter ec = (ErrorCounter)it.next();
        // out.println(it.next());
        out.println(ec);
      }
      out.println();
    } else {
      // out.println("\nNo Errors.\n");
    }
  }

  public String getNaam() {
    return naam;
  }
}