package nl.utopics.ndv.readlog;

import java.util.*;

/**
 * Title:        Readlog
 * Description:  Hulp projectje om logs multilevel in te kunnen lezen.
 * Copyright:    Copyright (c) 2002
 * Company:      Utopics
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * helper class for sorting service call summaries.
 */
public class ServiceCallSummaryComparator implements Comparator {

  public ServiceCallSummaryComparator() {

  }

  public int compare(Object o1, Object o2) {
    ServiceCallSummary summ1 = (ServiceCallSummary)o1;
    ServiceCallSummary summ2 = (ServiceCallSummary)o2;
    return summ1.getNaam().compareTo(summ2.getNaam());
  }

  public boolean equals(Object o1, Object o2) {
    return (o1.equals(o2));
  }

}