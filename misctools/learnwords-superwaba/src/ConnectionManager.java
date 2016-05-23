/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * manages database/catalog connections, because on Palm only one connection
 * to the same DB can be open.
 *
 * For now only check if the requested connection is the same as the main connection;
 * if so, return this one, otherwise create a new one.
 */
public class ConnectionManager {


  /**
   * mainList reference to wordlist used by LearnWords.
   */
  WordList mainList = null;

  /**
   * Constructor.
   * @param aMainList reference to wordlist used by LearnWords.
   */
  public ConnectionManager(WordList aMainList) {
    mainList = aMainList;
  }

  public WordList getConnection(String listname) {
    WordList conn = null;
    if (listname.compareTo(mainList.getCurrentListname()) == 0) {
      conn = mainList;
    } else {
      conn = new WordList();
      conn.openList(listname, true); // open readonly for now.
    }
    return conn;
  }

  /**
   * if conn is the same as mainList, don't close it, otherwise do.
   */
  public void closeConnection(WordList conn) {
    if (!conn.equals(mainList)) {
      conn.close();
      conn = null;
    }
  }

}