import waba.io.Catalog;
import waba.io.ResizeStream;
import waba.io.DataStream;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * Wrapper around a wordlist-database. Used by LearnSession and
 * WoordOverzichtWindow/WoordDetailWindow.
 *
 * Only in this will the extension (.NgDB.DATA) be added; all interfaces
 * use the base-name.
 *
 * Keep on open connection to the database, which should cost less memory.
 */
public class WordList {

  /**
   * refs to database and streams
   */
  Catalog cat = null;
  ResizeStream rs = null;
  DataStream ds = null;

  /**
   * current list/database name
   */
  private String currentListname = null;

  private String currentWord = null;
  private String currentTrans = null;

  public WordList() {
  }

  /**
   * open connection naar DB.
   */
  public void openList(String listname, boolean readonly) {
    close(); // close current list.
    currentListname = listname;
    // bugfix 1-3-2003: when name contains a dot (not the extension), a runtime
    // extension was inadvertedly thrown
    // if (listname.indexOf(".") < 0) {
    if (listname.indexOf(Util.DBEXTENSION) < 0) {
      listname = listname + Util.DBEXTENSION;
    } else {
      throw new RuntimeException("WordList.openList: name with ext: " + listname);
    }

    if (readonly) {
      cat = new Catalog(listname, Catalog.READ_ONLY);
    } else {
      cat = new Catalog(listname, Catalog.READ_WRITE);
    }
    // Util.message("WordList.openList: catalog geoepend: " + listname);
    if (cat.isOpen()) {
      // Util.message("WordList.openlist: catalog inderdaad open");
      rs = new ResizeStream(cat, 512);
      ds = new DataStream(rs);
    } else {
      Util.message("WordList.openlist: catalog NIET open");
      cat = null;
      rs = null;
      ds = null;
    }
  }

  public String getCurrentListname() {
    return currentListname;
  }

  public int getCount() {
    return cat.getRecordCount();
  }

  /**
   * close current DB connection
   */
  public void close() {
    if (cat != null) {
      ds.close();
      ds = null;
      rs.close();
      rs = null;
      cat.close();
      cat = null;
    }
  }

  public void setRecord(int idx) {
    cat.setRecordPos(idx);
    currentWord = ds.readString();
    currentTrans = ds.readString();
  }

  public String getCurrentWord() {
    return currentWord;
  }

  public String getCurrentTrans() {
    return currentTrans;
  }

  public int getCurrentRecord() {
    return cat.getRecordPos();
  }

  /**
   * get word + trans for display in WoordOverzichtWindow
   */
  public String getWordTrans(int idx) {
    String word, trans;
    cat.setRecordPos(idx);
    word = ds.readString();
    trans = ds.readString();
    return word + "/" + trans;
  }

  /**
   * get word + trans for export
   */
  public String getWordTransExport(int idx) {
    String word, trans;
    cat.setRecordPos(idx);
    word = ds.readString();
    trans = ds.readString();
    return word + Util.TAB + trans;
  }


}