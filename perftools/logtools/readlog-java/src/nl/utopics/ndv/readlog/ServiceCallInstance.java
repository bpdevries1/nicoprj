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

/**
 * Toplevel method-call, i.e. service-call. Contains MethodInstance on toplevel,
 * which contains sublevels.
 */
public class ServiceCallInstance {

  /**
   * reference to toplevel method-instance
   */
  private MethodInstance miTop = null;

  /**
   * reference to toplevel method-summary.
   */
  private MethodSummary msTop = null;

  /**
   * thread-id
   */
  private String thread = null;

  /**
   * starttijd uit de log
   */
  private String starttijd = null;

  /**
   * eindtijd uit de log
   */
  private String eindtijd = null;

  /**
   * lijst van ERROR´s tijdens deze service call
   */
  private ArrayList errors = new ArrayList();

  /**
   * constructor, set thread and starttijd.
   */
  public ServiceCallInstance(String aThread, String aStarttijd) {
    thread = aThread;
    starttijd = aStarttijd;
  }

  public void setEindtijd(String aEindtijd) {
    eindtijd = aEindtijd;
  }

  public String getEindtijd() {
    return eindtijd;
  }

  public void setTopMethodInstance(MethodInstance mi) {
    miTop = mi;
  }

  public MethodInstance getTopMethodInstance() {
    return miTop;
  }

  /**
   * print this object to stdout, called for toplevel objects.
   */
  public void print(PrintStream out, boolean alleenvoltooide) {
    if ((this.eindtijd != null) || (!alleenvoltooide)) {
      out.println("");
      out.println(this.starttijd + " -> " + this.eindtijd + " (" + this.thread + ")");
      miTop.print(out, 0);
      printErrors(out);
      out.println("---");
      out.flush();
    }
  }

  public void addError(LineStruct ls) {
    // System.err.println("*** Added error: " + ls );
    errors.add(ls); // methode bevat hier error-tekst
  }

  private void printErrors(PrintStream out) {
    if (errors.size() > 0) {
      out.println("\nErrors:");
      Iterator it = errors.iterator();
      while (it.hasNext()) {
        out.println(it.next());
      }
      out.println();
    } else {
      // out.println("\nNo Errors.\n");
    }
  }

  public List getErrors() {
    return errors;
  }

}