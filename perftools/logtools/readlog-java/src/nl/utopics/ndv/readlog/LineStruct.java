package nl.utopics.ndv.readlog;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

public class LineStruct {

  /**
   * soorten regels
   */
  public static final int LS_NONE     = -1;
  public static final int LS_START    = 0;
  public static final int LS_EIND     = 1;
  public static final int LS_ERROR    = 2;

  public static final int COMPSTART = (new String("nl.achmea.aol.")).length();

  /**
   * datum/tijd in regel
   */
  public String datumTijd = null;

  /**
   * thread nummer
   */
  public String thread = null;

  /**
   * componentnaam, alles tussen nl.achmea.aol. en de volgende punt.
   */
  public String componentnaam = null;

  /**
   * methode naam, of fout-tekst.
   */
  public String methode = null;

  /**
   * geeft aan of het een startregel, stopregel (met tijd), of error-regel is
   */
  // public boolean isStartRegel = false;
  public int soortRegel = LS_NONE;

  /**
   * tijd in milleseconden in geval van een stopregel
   */
  public int tijd = 0;

  /**
   * regelnummer
   */
  int linenumber = -1;

  /**
   * constructor.
   */
  // public LineStruct(String aDatumTijd, String aThread, String aMethode, boolean aIsStartRegel, int aTijd) {
  public LineStruct(String aDatumTijd, String aThread, String packageClass, String aMethode, int aSoortRegel, int aTijd, int aLinenumber) {
    datumTijd = aDatumTijd;
    thread = aThread;
    componentnaam = bepaalComponentnaam(packageClass);
    methode = aMethode;
    soortRegel = aSoortRegel;
    tijd = aTijd;
    linenumber = aLinenumber;
  }

  private String bepaalComponentnaam(String packageClass) {
    // nl.achmea.aol.offerte.objectmodel.CVerzekering
    packageClass = packageClass.substring(COMPSTART);
    int p = packageClass.indexOf(".");
    return packageClass.substring(0, p);
  }

  /**
   * print this line, used for debugging.
   */
  public void print() {
    // System.err.println("Line: " + this.datumTijd + " - " + this.thread + " - " + this.methode + " - " + this.tijd);
    System.err.println(toString());
  }

  public String toString() {
    return "Line: " + this.datumTijd + " - " + this.thread + " - " + this.componentnaam + " - " + this.methode + " - " + this.tijd + " [" + linenumber + "]";
  }

}