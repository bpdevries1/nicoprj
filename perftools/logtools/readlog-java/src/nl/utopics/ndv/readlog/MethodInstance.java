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
 * instantie van een method, met dus specifieke thread-id.
 */
public class MethodInstance {

  /**
   * componentnaam
   */
  private String componentnaam = null;

  /**
   * naam van deze methode
   */
  private String naam = null;

  /**
   * stop-naam van deze methode, gevuld als start- en stop-naam niet overeenkomen.
   */
  private String stopNaam = null;

  /**
   * level van deze instantie, waarschijnlijk niet nodig en is ook
   * lastig te vullen.
   */
  private int level = 0;

  /**
   * totaaltijd van deze call, incl. evt. subtijden.
   */
  private int tijd = -1;

  /**
   * totaal aan subtijden van deze call, berekende waarde.
   */
  private int subTijden = -1;

  /**
   * eigen tijd van deze call, berekende waarde: tijd - subTijden.
   */
  private int eigenTijd = -1;

  /**
   * start- en stopregelnummer voor debugging
   */
  private int startregel = -1;
  private int stopregel = -1;

  /**
   * lijst van subcalls bij deze call.
   */
  private ArrayList subcalls = new ArrayList();

  /**
   * constructor, waarschijnlijk beide params niet zinvol.
   */
  // public MethodInstance(String aNaam, String aThread, int aLevel, String aStarttijd) {
  public MethodInstance(String aComponentnaam, String aNaam, int aLevel, int aStartregel) {
    componentnaam = aComponentnaam;
    naam = aNaam;
    // thread = aThread;
    level = aLevel;
    startregel = aStartregel;
    // starttijd = aStarttijd;
  }

  public void setNaam(String aNaam) {
    naam = aNaam;
  }

  public String getComponentnaam() {
    return componentnaam;
  }

  public String getNaam() {
    return naam;
  }

  public void setTijd(int aTijd) {
    tijd = aTijd;
  }

  public int getTijd() {
    return tijd;
  }

  public int getEigenTijd() {
    return eigenTijd;
  }

  public int getSubTijden() {
    return subTijden;
  }

  public void addSubCall(MethodInstance aSubCall) {
    subcalls.add(aSubCall);
  }

  public List getSubCalls() {
    return subcalls;
  }

  /**
   * bereken subtijden en eigen tijd.
   * @pre: tijd is ingevuld, zowel in dit object als in sub-calls.
   */
  public void berekenTijden() {
    subTijden = 0;
    Iterator it = subcalls.iterator();
    while (it.hasNext()) {
      subTijden += ((MethodInstance)it.next()).getTijd();
    }
    eigenTijd = tijd - subTijden;
  }

  /**
   * set stopregel
   */
  public void setStopregel(int aStopregel) {
    stopregel = aStopregel;
  }

  public void print(PrintStream out, int level) {
    out.print(level + ". ");
    for (int i = 0; i < level; i++) {
      out.print("  ");
      // out.print("|-");
    }
    String prNaam = (stopNaam == null ? naam : naam + "/***/" + stopNaam);
    prNaam = componentnaam + "." + prNaam + " [" + startregel + ":" + stopregel + "] ";
    if (subTijden == 0) {
      out.println(prNaam + " (" + tijd + ")");
    } else {
      out.println(prNaam + " (" + tijd + " = " + eigenTijd + " + " + subTijden + ")");
    }
    Iterator it = this.subcalls.iterator();
    while (it.hasNext()) {
      ((MethodInstance)it.next()).print(out, level + 1);
    }
  }

  public void setStopNaam(String aNaam) {
    stopNaam = aNaam;
  }

  public String getStopNaam() {
    return stopNaam;
  }

}