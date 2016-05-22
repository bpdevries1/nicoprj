import waba.util.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

public class ListInfoItem {

  public int metaIndex = -1;
  public String label = null;
  public String listname = null;
  public Date date;
  public int nrounds;
  public boolean finished;
  public boolean reverse;
  public boolean random;
  public String notes;

  public ListInfoItem(String aListname, int aMetaIndex) {
    listname = aListname;
    metaIndex = aMetaIndex;
  }

  public void setInfo(Date aDate, int aNrounds, boolean aFinished, boolean aReverse,
      boolean aRandom, String aNotes) {
    date = aDate;
    nrounds = aNrounds;
    finished = aFinished;
    reverse = aReverse;
    random = aRandom;
    notes = aNotes;
  }
}