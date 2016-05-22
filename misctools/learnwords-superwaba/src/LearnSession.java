import waba.util.*;
import waba.sys.*;
import waba.io.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * A learning session, which keeps state between multiple executions of the
 * program. (old: WoordenLijst). Used by LearnWords and uses WordList.
 */
public class LearnSession {

  /**
   * ref to wordList, a wrapper for a word-database
   */
  WordList wordList = new WordList();

  /**
   * list with words which are to be asked.
   */
  private IntVector todoList = null;

  /**
   * list with wrong answers.
   */
  private IntVector wrongList = null;

  /**
   * Settings: reverse, random, rounds
   */
  private LearnSettings settings = null;

  /**
   * randomizer
   */
  private Random rnd = null;

  /**
   * round
   */
  private int round = 0;

  /**
   * total in this round.
   */
  private int nround = 0;

  /**
   * number correct in this round.
   */
  private int ncorrect = 0;

  /**
   * number wrong in this round.
   */
  private int nwrong = 0;

  /**
   * pointer/index of current element in DB
   */
  private int idxCurrentWord = 0;

  /**
   * if the current (last) word is an old one, from the error list, the count for
   * old should be given + 1.
   */
  private boolean isCurrentWordOld = false;

  /**
   * current word and translation. These are the real word and translation.
   * in getCurrentWord and -Trans they will be reversed if 'reverse' is true.
   */
  private String currentWord = null;
  private String currentTrans = null;

  public LearnSession(LearnSettings aSettings) {
    rnd = new Random();
    settings = aSettings;
  }

  public void toggleReverse() {
    settings.setReverse(!settings.isReverse());
  }

  public boolean isReverse() {
    return settings.isReverse();
  }

  public void toggleRandom() {
    settings.setRandom(!settings.isRandom());
  }

  public boolean isRandom() {
    return settings.isRandom();
  }

  public void toggleAutomatic() {
    settings.setAutomatic(!settings.isAutomatic());
  }

  public boolean isAutomatic() {
    return settings.isAutomatic();
  }

  /**
   * read wordlist: open wordlist-db and keep it open. First close previous list.
   * @return previous info item, use for updating listoverviewwindow.
   */
  public ListInfoItem readWords(String listname) {
    ListInfoItem item = saveStatistics();
    wordList.openList(listname, true);
    // keep reverse and random settings from the last list.
    return item;
  }

  public WordList getCurrentList() {
    return wordList;
  }

  public String getCurrentListName() {
    return wordList.getCurrentListname();
  }

  public void reset() {
    round = 0;
    int n = 0;
    n = wordList.getCount();
    // Util.message("Reset, n = " + n);
    todoList = new IntVector(n);
    for (int i = 0; i < n; i++) {
      todoList.add(i);
    }
  }

  public void startRound() {
    round++;
    if (round > 1) {
      todoList = wrongList;
    } else {
      // nothing, but should fill wordlist here.
    }
    nround = todoList.size();
    nwrong = 0;
    ncorrect = 0;
    wrongList = new IntVector();
  }

  public boolean isRoundFinished() {
    return (ncorrect + nwrong == nround);
  }

  /**
   * get the next word from the list.
   * possibly use new algorithm here, with min/maxErrors.
   *
   * @post idxCurrentWord points to new current word, also set in wordList.
   * @post if new word => removed from todo-list.
   */
  public void nextWord() {
    if (settings.isRounds()) {
      nextWordNew();
    } else {
      // use new algorithm
      if (nwrong <= settings.getMinErrors()) {
        // use normal way, get a new word
        nextWordNew();
      } else if (nwrong >= settings.getMaxErrors()) {
        // always get an old word
        nextWordOld();
      } else {
        // determine chance, get old or new word.
        if (isGetNewWord()) {
          nextWordNew();
        } else {
          nextWordOld();
        }
      }
    }
  }

  /**
   * determine if the next word should be from the new list or from the old list.
   * @pre the number of errors is between minErrors and maxErrors.
   */
  private boolean isGetNewWord() {
/*
    int number = settings.getMaxErrors() - settings.getMinErrors();
    Util.message("nwrong: " + nwrong);
    Util.message("number: " + number);
    for (int i = 0; i < 20; i++) {
      int rndVal = rnd.nextInt(number);
      Util.message("random: " + rndVal);
    }
*/
    int rndVal = rnd.nextInt(settings.getMaxErrors() - settings.getMinErrors());
    if (nwrong - rndVal <= settings.getMinErrors()) {
      Util.message("should get a new word");
      return true;
    } else {
      Util.message("should get an old word");
      return false;
    }
  }

  /**
   * get a new word from the todo-list
   */
  private void nextWordNew() {
    Util.message("getting new word");
    int idx = 0;
    if (settings.isRandom()) {
      idx = rnd.nextInt(todoList.size());
    } else {
      idx = 0;
    }
    idxCurrentWord = todoList.elementAt(idx); // pointer naar DB
    wordList.setRecord(idxCurrentWord);
    todoList.del(idx);
    isCurrentWordOld = false;
  }

  /**
   * get a new word from the error-list (always take the first, and new wrong words
   * to the end)
   */
  private void nextWordOld() {
    Util.message("getting old word");
    int idx = 0;
    idxCurrentWord = wrongList.elementAt(idx); // pointer naar DB
    wordList.setRecord(idxCurrentWord);
    wrongList.del(idx);
    nwrong--;
    isCurrentWordOld = true;
  }

  public String getCurrentWord() {
    if (settings.isReverse()) {
      return wordList.getCurrentTrans();
    } else {
      return wordList.getCurrentWord();
    }
  }

  public int getCurrentRecord() {
    return wordList.getCurrentRecord();
  }

  public String getCurrentTrans() {
    if (settings.isReverse()) {
      return wordList.getCurrentWord();
    } else {
      return wordList.getCurrentTrans();
    }
  }

  public void wordCorrect() {
    ncorrect++;
  }

  public void wordWrong() {
    nwrong++;
    wrongList.add(idxCurrentWord);
  }

  public int getRound() {
    return round;
  }

  public int getCountTotal() {
    return wordList.getCount();
  }

  public int getCountRound() {
    return nround;
  }

  public int getCountCorrect() {
    return ncorrect;
  }

  public int getCountWrong() {
    if (isCurrentWordOld) {
      // should also add the current old, wrong word.
      return (nwrong + 1);
    } else {
      return nwrong;
    }
  }

  /**
   * save current state to state-db (dbname, round number, wordt wrong, words todo etc.)
   * records:
   * * Control string: "LearnWords"
   * * name of DB and index in meta-DB.
   * * normal/reverse
   * * 4 status-fields: round, total, right, wrong
   * * todo-list
   * * wrong-list
   *
   * @pre: method is only called if there is some state to save, ie. state is not
   * IDLE or FINISHED
   */
  public void saveState() {
    Catalog catState = null;
    ResizeStream rsState = null;
    DataStream dsState = null;

    // Util.message("Saving state: " + Util.DBSTATE);

    try {
      catState = new Catalog(Util.DBSTATE, Catalog.CREATE);
      catState.delete(); // remove old state
      catState.close();
      catState = new Catalog(Util.DBSTATE, Catalog.CREATE);
      Util.message("Created DB for writing");
      if (catState.isOpen()) {
        rsState = new ResizeStream(catState, 512);
        dsState = new DataStream(rsState);
        rsState.startRecord();
        dsState.writeString(Util.CHECKSYMBOL);
        rsState.endRecord();
        rsState.startRecord();
        dsState.writeString(wordList.getCurrentListname());
        dsState.writeInt(MetaData.getInfoItem(wordList.getCurrentListname()).metaIndex);
        rsState.endRecord();
        rsState.startRecord();
        dsState.writeBoolean(settings.isReverse());
        dsState.writeBoolean(settings.isRandom());
        rsState.endRecord();
        // status fields
        rsState.startRecord();
        dsState.writeInt(round);
        dsState.writeInt(nround);
        dsState.writeInt(ncorrect);
        dsState.writeInt(nwrong);
        rsState.endRecord();

        // todo-list, incl. current element, finished with -1
        rsState.startRecord();
        dsState.writeInt(idxCurrentWord);
        for (int i = 0; i < todoList.size(); i++) {
          dsState.writeInt(todoList.elementAt(i));
        }
        dsState.writeInt(-1);
        rsState.endRecord();

        // wrong-list, finished with -1
        rsState.startRecord();
        for (int i = 0; i < wrongList.size(); i++) {
          dsState.writeInt(wrongList.elementAt(i));
        }

        dsState.writeInt(-1);
        rsState.endRecord();

        // Util.message("Saved state");
      } else {
        Vm.debug("could not create state DB");
      }
    } catch (Exception e) {
      // error, always log
      Vm.debug("Could not save state to db");
      if (!Util.ONPALM) {
        e.printStackTrace();
      }
    } finally {
      if (dsState != null) {
        dsState.close();
      }
      if (rsState != null) {
        rsState.close();
      }
      if (catState != null) {
        catState.close();
      }
    }

  }

  /**
   * remove state from database, to be called if state = IDLE or FINISHED.
   */
  public void clearState() {
    Catalog catState = null;
    try {
      catState = new Catalog(Util.DBSTATE, Catalog.WRITE_ONLY);
      catState.delete();
      if (catState.isOpen()) {
        catState.close();
      }
    } catch (Exception e) {
      Vm.debug("State DB could not be deleted");
    }
  }

  /**
   * load state from last session from state-db.
   * returns true if succesfully loaded, in order to update UI
   * * Control string: "LearnWords"
   * * naam DB and index in meta-DB.
   * * normal/reverse
   * * 4 status-fields: round, total, right, wrong
   * * todo-list
   * * fout-list
   */
  public boolean loadState() {
    Catalog catState = null;
    ResizeStream rsState = null;
    DataStream dsState = null;
    boolean loaded = true;
    int currentRecord = 0;
    String line = null;

    try {
      catState = new Catalog(Util.DBSTATE, Catalog.READ_ONLY);
      if (catState.isOpen()) {
        rsState = new ResizeStream(catState, 512);
        dsState = new DataStream(rsState);
        catState.setRecordPos(currentRecord++);
        line = dsState.readString();
        if (line.compareTo(Util.CHECKSYMBOL) == 0) {
          // checksymbol found, assume structure is correct.
          catState.setRecordPos(currentRecord++);
          line = dsState.readString();
          int metaIndex = dsState.readInt();
          MetaData.readInfoItem(metaIndex, line);
          wordList.openList(line, true);

          catState.setRecordPos(currentRecord++);
          settings.setReverse(dsState.readBoolean());
          settings.setRandom(dsState.readBoolean());

          // status-fields
          catState.setRecordPos(currentRecord++);
          round = dsState.readInt();
          nround = dsState.readInt();
          ncorrect = dsState.readInt();
          nwrong = dsState.readInt();

          // todo, reset todolist
          todoList = new IntVector(nround);
          catState.setRecordPos(currentRecord++);
          int idx = -1;
          do {
            idx = dsState.readInt();
            if (idx >= 0) {
              todoList.add(idx);
            }
          } while (idx != -1);

          // wrong
          wrongList = new IntVector(nround);
          catState.setRecordPos(currentRecord++);
          idx = -1;
          do {
            idx = dsState.readInt();
            if (idx >= 0) {
              wrongList.add(idx);
            }
          } while (idx != -1);
        } else {
          loaded = false;
        }
      } else {
        loaded = false;
      }
    } catch (Exception e) {
      // error, always log
      Vm.debug("Could not load state from db");
      if (!Util.ONPALM) {
        e.printStackTrace();
      }
      loaded = false;
    } finally {
      if (dsState != null) {
        dsState.close();
      }
      if (rsState != null) {
        rsState.close();
      }
      if (catState != null) {
        catState.close();
      }
    }
    return loaded;

  }

  /**
   * save statistics in meta db
   */
  public ListInfoItem saveStatistics() {
    ListInfoItem item = null;
    if (wordList.getCurrentListname() != null) {
      // Util.message("Saving state for: " + wordList.getCurrentListname());
      item = MetaData.saveStatistics(getCurrentListName(), new Date(), round,
             isRoundFinished(), settings.isReverse(), settings.isRandom());
    }
    return item;
  }

}