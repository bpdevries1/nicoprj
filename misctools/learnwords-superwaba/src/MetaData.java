import waba.io.*;
import waba.sys.Vm;
import waba.util.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * Manager class for metadata list. Fields in the DB:
 * 0. Label: label to display in DBOverzichtWindow, including stats.
 * 1. Name of the DB, not including extension
 * 2. Date when this DB was last learned, saved as a Date
 * 3. #rounds for this last learning, saved as an integer;
 * 4. finished: boolean to denote whether the last learning was finished.
 * 5. reverse: boolean to denote whether last learning was reverse.
 * 6. random: boolean to denote whether last learning was in random order.
 * 7. Notes: a string to be filled by the user.
 * 8. Category: voorlopig niet, maar wel placeholder, omdat anders DB geconverteerd moet worden.
 *
 * @later: save state for all unfinished DB's???
 */
public class MetaData {

  /**
   * cache for keeping listnames and InfoItems; hashTable does not work:
   * no exceptions but add does not really add anything to the hashtable, count
   * stays 0.
   */
  // private static Hashtable cache = new Hashtable(5);
  private static Vector cache = new Vector();

  /**
   * open metaDB lazy. When created, check if DB exists, otherwise call refreshDBs
   */
  private static Catalog catMeta = null;
  private static ResizeStream rsMeta = null;
  private static DataStream dsMeta = null;

  public static int getCountDBs() {
    openMeta();
    // Util.message("getAantalDBs: catMeta = " + catMeta);
    return catMeta.getRecordCount();
  }

  /**
   * get the label of the List for display in ListOverviewWindow. Only method
   * that does not work with ListInfoItems.
   */
  public static String getListBoxItem(int idx) {
    // first field of record
    catMeta.setRecordPos(idx);
    return dsMeta.readString();
  }

  /*
   * Save statistics:
     * 0. Label: label to display in DBOverzichtWindow, including stats.
     * 1. Name of the DB, not including extension
     * 2. Date when this DB was last learned, saved as a Date
     * 3. #rounds for this last learning, saved as an integer;
     * 4. finished: boolean to denote whether the last learning was finished.
     * 5. reverse: boolean to denote whether last learning was reverse.
     * 6. random: boolean to denote whether last learning was in random order.
     * 7. Notes: a string to be filled by the user.
     * 8. Category: voorlopig niet, maar wel placeholder, omdat anders DB geconverteerd moet worden.
  */
  public static ListInfoItem saveStatistics(String listname, Date date, int nRounds, boolean finished,
          boolean reverse, boolean random) {
    Util.message("MetaData.saveStats: start");
    ListInfoItem item = getInfoItem(listname);
    if (item == null) {
      Util.message("Saving stats, listname not found: " + listname);
      throw new RuntimeException("Saving stats, listname not found: " + listname);
    } else {
      // update infoItem
      item.label = makeLabel(listname, date, nRounds, finished, reverse, random);
      item.date = date;
      item.nrounds = nRounds;
      item.finished = finished;
      item.reverse = reverse;
      item.random = random;

      // writeRecord(item);
      saveItem(item);

    }
    return item;
  }

  /**
   * saves an item to the meta db
   * note: restartRecord does not resize, behaves vaguely;
   * workaround is to delete and re-insert the record.
   */
  public static void saveItem(ListInfoItem item) {
    Util.message("MetaData.saveItem: start");

    // delete en re-insert does work.
    catMeta.setRecordPos(item.metaIndex);
    catMeta.deleteRecord();
    rsMeta.startRecord(item.metaIndex);

    dsMeta.writeString(item.label);
    dsMeta.writeString(item.listname);
    if (item.date != null) {
      dsMeta.writeInt(item.date.getDateInt());
    } else {
      dsMeta.writeInt(0);
    }
    dsMeta.writeInt(item.nrounds); //
    dsMeta.writeBoolean(item.finished); // finished, not used with empty date
    dsMeta.writeBoolean(item.reverse); // reverse, not used with empty date
    dsMeta.writeBoolean(item.random); // random, not used with empty date
    dsMeta.writeString(item.notes); // notes
    dsMeta.writeString(""); // category, not used for now.
    rsMeta.endRecord();

  }

  /**
   * make a label in the form: Getallen (31-5:NN:4?)
   */
  private static String makeLabel(String listname, Date date, int nRounds,
         boolean finished, boolean reverse, boolean random) {
    return listname + " (" + date.getDay() + "-" + date.getMonth() + ":" + (reverse?"R":"N") +
        (random?"R":"N") + ":" + nRounds + (finished?"!":"?") + ")";
  }

  /**
   * get listInfoItem and return
   */
  public static ListInfoItem getInfoItem(String listname) {
    ListInfoItem item = getCache(listname);
    if (item == null) {
      Util.message("MetaData.getInfoItem:listname not found: " + listname + "***");
      throw new RuntimeException("listname not found: " + listname);
    }
    return item;
  }

  /**
   * fill listInfoItem and return
   */
  public static ListInfoItem readInfoItem(int metaIndex, String listname) {
    openMeta();
    ListInfoItem item = null;
    catMeta.setRecordPos(metaIndex);
    String label = dsMeta.readString(); // ignore label
    String name2 = dsMeta.readString(); // check listname
    if ((listname == null) || (listname.compareTo(name2) == 0)) {
      if (listname != null) {
        item = getCache(listname);
      }
      if (item == null) {
        item = new ListInfoItem(listname, metaIndex);
        cache.add(item);
      }
      item.label = label;
      item.listname = name2;
      int d = dsMeta.readInt();
      if (d > 0) {
        item.date = new Date(d);
      } else {
        item.date = null;
      }
      item.nrounds = dsMeta.readInt();
      item.finished = dsMeta.readBoolean();
      item.reverse = dsMeta.readBoolean();
      item.random = dsMeta.readBoolean();
      item.notes = dsMeta.readString();

    } else {
      Vm.debug("Item read != listname: " + name2 + "/" + listname);
      throw new RuntimeException("Item read != listname: " + name2 + "/" + listname);
    }
    Util.message("MetaData.readInfoItem:end:listname: " + item.listname);
    return item;
  }

  /**
   * Refreshes meta-DB: checks which word-db's exist on Palm and puts them
   * in the meta-DB.
   *
   * @post: DBs are read, catMeta is opened for reading (again)
   */
  public static void refreshDBs() {
    try {
      Util.message("refresh dbs: start");
      // 1. read current list
      Vector items = null;
      int nItems = 0;
      doOpenMeta();
      if (catMeta != null) {
        nItems = catMeta.getRecordCount();
        items = new Vector(nItems + 10);
        for (int i = 0; i <  nItems; i++) {
          // second field of record
          catMeta.setRecordPos(i);
          dsMeta.readString(); // first field: label/listboxitem
          items.add(dsMeta.readString()); // second field contains name
        }
      } else {
        catMeta = new Catalog(Util.DBMETA, Catalog.CREATE);
        items = new Vector(50);
      }

      // 2. then add new items
      if (catMeta.isOpen()) {
        rsMeta = new ResizeStream(catMeta, 512);
        dsMeta = new DataStream(rsMeta);
        String[] cats = Catalog.listCatalogs();
        String strCat = null;
        String name = null;
        int p = 0;
        if (cats != null) {
          int insertPos = -1;
          for (int i = 0; i < cats.length; i++) {
            strCat = cats[i];
            if (strCat.substring(0,1).compareTo("_") != 0) {
              p = strCat.indexOf(Util.DBEXTENSION);
              if (p > 0) {
                name = strCat.substring(0, p);
                if (items.indexOf(name) < 0) {
                  insertPos = determineInsertPos(items, name);
                  Util.message("Adding to items: " + name + " at " + insertPos);
                  items.insert(insertPos, name);
                  insertRecord(insertPos, name);
                }
              } // if correct extension
            } // if no _
          } // for  each cat

          // close and open DB, so data will be persisted
          closeMeta();
          openMeta();

        } // if cats not null
      } // if catmeta is open
    } catch (Exception e) {
      // error, always log
      Vm.debug("Could not save metadata to db");
      if (!Util.ONPALM) {
        e.printStackTrace();
      }
      catMeta = null;
      dsMeta = null;
      rsMeta = null;
    } // try
  } // refreshMeta

  /**
   * find insert position within items for name
   * @pre: items is sorted.
   */
  private static int determineInsertPos(Vector items, String name) {
    int n = items.getCount();
    int pos = 0;
    while ((pos < n) && (((String)items.elementAt(pos)).compareTo(name) < 0)) {
      pos++;
    }
    return pos;
  }

  /**
   * write a record to the db.
   * 0. Label: label to display in DBOverzichtWindow, including stats.
   * 1. Name of the DB, not including extension
   * 2. Date when this DB was last learned, saved as a Date
   * 3. #rounds for this last learning, saved as an integer;
   * 4. finished: boolean to denote whether the last learning was finished.
   * 5. reverse: boolean to denote whether last learning was reverse.
   * 6. random: boolean to denote whether last learning was in random order.
   * 7. Notes: a string to be filled by the user.
   * 8. Category: voorlopig niet, maar wel placeholder, omdat anders DB geconverteerd moet worden.
   */
  private static void insertRecord(int insertPos, String listname) {
    Util.message("insertRecord: Start");
    rsMeta.startRecord(insertPos);
    dsMeta.writeString(listname); // label
    dsMeta.writeString(listname); // name
    dsMeta.writeInt(0); // empty date
    dsMeta.writeInt(0); // empty #rounds, not used with empty date
    dsMeta.writeBoolean(false); // finished, not used with empty date
    dsMeta.writeBoolean(false); // reverse, not used with empty date
    dsMeta.writeBoolean(false); // random, not used with empty date
    dsMeta.writeString(""); // notes
    dsMeta.writeString(""); // category, not used for now.
    rsMeta.endRecord();
  }

  public static void closeMeta() {
    if (catMeta != null) {
      dsMeta.close();
      dsMeta = null;
      rsMeta.close();
      rsMeta = null;
      catMeta.close();
      catMeta = null;
    }
  }

  /**
   * Open Meta DB for reading and writing.
   *
   * @post catMeta is geopend, ongelijk aan null.
   */
  private static void openMeta() {
    doOpenMeta();
    if (catMeta == null) {
      Vm.debug("openMeta: db not open, create new.");
      refreshDBs();
    }
  }

  /**
   * (just) try to open metadatabase, nothing else.
   */
  private static void doOpenMeta() {
    if (catMeta == null) {
      try {
        catMeta = new Catalog(Util.DBMETA, Catalog.READ_WRITE);
        if (catMeta.isOpen()) {
          rsMeta = new ResizeStream(catMeta, 512);
          dsMeta = new DataStream(rsMeta);
        } else {
          catMeta = null;
          rsMeta = null;
          dsMeta = null;
        }
      } catch (Exception e) {
        // error, always log
        Vm.debug("Could not open metadata db");
        if (!Util.ONPALM) {
          e.printStackTrace();
        }
        catMeta = null;
        rsMeta = null;
        dsMeta = null;
      } // try
    } // if catMeta == null

  }

  /**
   * methods for debugging uses
   * @pre: db is open, i0 := currentPost
   * @post: db is open, currentPos = i0
   */
/*
  private static void printMeta() {
    int cur = catMeta.getRecordPos();
    Util.message("MetaData database, currentpos = " + cur);
    int n = catMeta.getRecordCount();
    for (int i = 0; i < n; i++) {
      Util.message("Record: " + i);
      catMeta.setRecordPos(i);
      Util.message("label: " + dsMeta.readString());
      Util.message("name: " + dsMeta.readString());
      Util.message("date: " + dsMeta.readInt());
      Util.message("nrounds: " + dsMeta.readInt());
      Util.message("finished: " + dsMeta.readBoolean());
      Util.message("reverse: " + dsMeta.readBoolean());
      Util.message("random: " + dsMeta.readBoolean());
      Util.message("notes: " + dsMeta.readString());
      Util.message("category: " + dsMeta.readString());
      Util.message("---");
    }
    catMeta.setRecordPos(cur);
  }
*/

/*
  private static void printCache() {
    Util.message("Cache: " + cache.getCount());
    for (int i = 0; i < cache.getCount(); i++) {
      Util.message("" + ((ListInfoItem)cache.get(i)).listname);
    }
  }
*/

/*
  private static void printItem(ListInfoItem item) {
    Util.message("Item: ");
    Util.message("label: " + item.label);
    Util.message("listname: " + item.listname);
    Util.message("date: " + item.date);
    Util.message("nrounds: " + item.nrounds); //
    Util.message("finished: " + item.finished); // finished, not used with empty date
    Util.message("reverse: " + item.reverse); // reverse, not used with empty date
    Util.message("random: " + item.random); // random, not used with empty date
    Util.message("notes: " + item.notes); // notes
  }
*/

  private static ListInfoItem getCache(String listname) {
    ListInfoItem item = null;
    int n = cache.getCount();
    for (int i = 0; (i < n) && (item == null); i++) {
      item = (ListInfoItem)cache.get(i);
      if (item.listname.compareTo(listname) != 0) {
        item = null;
      }
    }
    return item;
  }
}
