package nl.utopics.ndv.readlog;

import java.util.*;
import java.io.*;
import java.text.*;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

public class MethodSummary {

  /**
   * componentnaam
   */
  private String componentnaam = null;

  /**
   * name of the methodcalls
   */
  private String naam = null;

  /**
   * instances of the call
   */
  private ArrayList instances = new ArrayList();

  /**
   * sub summary's
   * store as ArrayList because want to keep the order in which elements are added.
   */
  // private HashMap subCalls = new HashMap();
  private ArrayList subCalls = new ArrayList();

  /**
   * used for formatting doubles
   */
  private NumberFormat nf = NumberFormat.getInstance();

  public MethodSummary(String aComponentnaam, String aNaam) {
    componentnaam = aComponentnaam;
    naam = aNaam;
  }

  /**
   * find the subcall with aNaam or create a new one.
   */
  public MethodSummary getSub(String aComponentnaam, String aNaam) {
    // MethodSummary result = (MethodSummary)subCalls.get(aNaam);
    MethodSummary result = null;

    Iterator iter = subCalls.iterator();
    MethodSummary ms = null;
    while (iter.hasNext()) {
      ms = (MethodSummary)iter.next();
      if (ms.getNaam().equals(aNaam)) {
        result = ms;
      }
    }

    if (result == null) {
      result = new MethodSummary(aComponentnaam, aNaam);
      // subCalls.put(aNaam, result);
      subCalls.add(result);
    }
    return result;
  }

  /**
   * add a method instance to this summary.
   */
  public void addMethodInstance(MethodInstance mi) {
    instances.add(mi);
  }

/*
  public HashMap getSubCalls() {
    return subCalls;
  }

  public List getInstances() {
    return instances;
  }
*/

  public void print(PrintStream out, int level, int callercalls, int nservicecalls, boolean showPercentiles) {
    // out.print(level + ". ");
    out.print(level + "\t");
/*
    for (int i = 0; i < level; i++) {
      out.print("  ");
      // out.print("|-");
    }
*/
    int n = instances.size();
    double nGem = (n * 1.0) / callercalls;
    double gemTijd = bepaalTijdGem();
    double gemTijdPerCaller = gemTijd * nGem;
    double gemEigenTijd = bepaalEigenTijdGem();
    double gemEigenTijdPerCaller = gemEigenTijd * nGem;

    double nGemPerService = (n * 1.0) / nservicecalls;
    double gemTijdPerService = gemTijd * nGemPerService;
    double gemEigenTijdPerService = gemEigenTijd * nGemPerService;

    List percEigen = bepaalEigenTijdPercentielen();
    List perc = bepaalTijdPercentielen();

    initNumberFormat();

    out.print(componentnaam + "\t" + naam + "\t" + n + "\t" + format(gemTijd)
        + "\t" + format(gemEigenTijd)
        + "\t" + format(nGemPerService) + "\t" + format(gemTijdPerService) + "\t" + format(gemEigenTijdPerService));
    if (showPercentiles) {
      for (int i = 0; i < N_PERC; i++) {
        out.print("\t" + ((Integer)percEigen.get(i)).intValue());
      }
      for (int i = 0; i < N_PERC; i++) {
        out.print("\t" + ((Integer)perc.get(i)).intValue());
      }
    }

    out.println();
    // Iterator it = this.subCalls.keySet().iterator();
    Iterator it = this.subCalls.iterator();
    MethodSummary sub = null;
    while (it.hasNext()) {
      // sub = (MethodSummary)subCalls.get(it.next());
      sub = (MethodSummary)it.next();
      sub.print(out, level + 1, n, nservicecalls, showPercentiles);
    }
  }

  private void initNumberFormat() {
    nf.setMaximumFractionDigits(0);
  }

  private String format(double val) {
    return nf.format(val);
  }

  private double bepaalEigenTijdGem() {
    int n = 0;
    double totaalTijd = 0.0;
    MethodInstance mi = null;
    Iterator it = instances.iterator();
    while (it.hasNext()) {
      mi = (MethodInstance)it.next();
      n++;
      // totaalTijd += mi.getEigenTijd();
      totaalTijd += mi.getEigenTijd();
    }
    return (totaalTijd / n);
  }

  private double bepaalTijdGem() {
    int n = 0;
    double totaalTijd = 0.0;
    MethodInstance mi = null;
    Iterator it = instances.iterator();
    while (it.hasNext()) {
      mi = (MethodInstance)it.next();
      n++;
      // totaalTijd += mi.getEigenTijd();
      totaalTijd += mi.getTijd();
    }
    return (totaalTijd / n);
  }

  public List getInstances() {
    return instances;
  }

  public int getNInstances() {
    return instances.size();
  }

  public String getNaam() {
    return naam;
  }

  /**
   * constanten voor percentielen.
   */
  // int N_PERC = 4;
  // int PERC[] = {10, 50, 90, 95};
  public static int N_PERC = 3;
  // int PERC[] = {50, 75, 98};
  public static int PERC[] = {50, 90, 98};

  /**
   * bepaal vooraf vastgesteld percentielen.
   * @return a list of Integers.
   */
  private List bepaalEigenTijdPercentielen() {
    // sorteer lijst van instances op eigentijd
    Collections.sort(instances, new Comparator() {
      public int compare(Object o1, Object o2) {
        int t1 = ((MethodInstance)o1).getEigenTijd();
        int t2 = ((MethodInstance)o2).getEigenTijd();
        if (t1 < t2) {
          return -1;
        } else if (t1 > t2) {
          return 1;
        } else {
          return 0;
        }
      }
    } );

    ArrayList result = new ArrayList();
    int index = 0;
    int nlist = instances.size();
    for (int i = 0; i < N_PERC; i++) {
      index = (int)Math.floor(PERC[i] * 1.0 / 100.0 * nlist);
      if ((index >= 0) && (index < nlist)) {
        result.add(new Integer(((MethodInstance)instances.get(index)).getEigenTijd()));
      } else {
        result.add(new Integer(0));
      }
    }
    return result;
  }

  /**
   * bepaal vooraf vastgesteld percentielen.
   * @return a list of Integers.
   */
  private List bepaalTijdPercentielen() {
    // sorteer lijst van instances op eigentijd
    Collections.sort(instances, new Comparator() {
      public int compare(Object o1, Object o2) {
        int t1 = ((MethodInstance)o1).getTijd();
        int t2 = ((MethodInstance)o2).getTijd();
        if (t1 < t2) {
          return -1;
        } else if (t1 > t2) {
          return 1;
        } else {
          return 0;
        }
      }
    } );

    ArrayList result = new ArrayList();
    int index = 0;
    int nlist = instances.size();
    for (int i = 0; i < N_PERC; i++) {
      index = (int)Math.floor(PERC[i] * 1.0 / 100.0 * nlist);
      if ((index >= 0) && (index < nlist)) {
        result.add(new Integer(((MethodInstance)instances.get(index)).getTijd()));
      } else {
        result.add(new Integer(0));
      }
    }
    return result;
  }


}