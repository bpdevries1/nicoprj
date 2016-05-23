import waba.ui.*;
import waba.sys.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 *
 * History
 * When       What
 * 23-2-2003  Bugfix: open list -> words overview -> select -> nullpointer.
 */

public class WordsOverviewWindow extends Window {

  /**
   * ref. to main-window, used for window-manager and also for starting a
   * session.
   */
  private LearnWords main = null;

  /**
   * ref to wordList, a wrapper for a word-database
   * now managed dynamically by ConnectionManager.
   */
  WordList wordList = null;

  ListBox words = null;
  Button learn = null;
  Button detail = null;
  Button export = null;
  Button close = null;

  public WordsOverviewWindow(LearnWords aMain) {
    super("Words Overview", NO_BORDER); // with caption and borders
    main = aMain;

    setRect(LEFT, TOP, Settings.screenWidth, Settings.screenHeight);

    words = new ListBox();
    learn = new Button("Select");
    detail = new Button("Detail");
    export = new Button("Export");
    close = new Button("Close");
    learn.setGap(3);
    detail.setGap(3);
    export.setGap(3);
    close.setGap(3);

    add(learn, LEFT, BOTTOM);
    add(detail, AFTER, SAME);
    add(export, AFTER, SAME);
    add(close, RIGHT, SAME);

    add(words);
    words.setRect(LEFT, TOP, FILL, this.getClientRect().height - learn.getPreferredHeight());
  }

  public void setList(String aListname) {
    words.removeAll();
    wordList = main.getConnectionManager().getConnection(aListname);

    int n = wordList.getCount();
    for (int i = 0; i < n; i++) {
      words.add(wordList.getWordTrans(i));
    }
    setTitle(aListname);
  }

  public void setCurrentPos(int pos) {
    words.select(pos); // this assumes that positions in darabase and listbox are the same.
  }

  /**
   * event handler
   */
  public void onEvent(Event event) {
    if (event.type == ControlEvent.PRESSED) {
      if (event.target == learn) {
        learnList();
      } else if (event.target == detail) {
        showWordDetail();
      } else if (event.target == export) {
        export();
      } else if (event.target == close) {
        main.getWindowManager().close(this);
      }
    }
  }

  private void learnList() {
    String currentList = wordList.getCurrentListname();
    main.getWindowManager().closeAllPopups();
    main.openWordList(currentList);
  }

  private void showWordDetail() {
    int idx = words.getSelectedIndex();
    if (idx != -1) {
      wordList.setRecord(idx);
      main.getWindowManager().showWordDetail(this.wordList.getCurrentListname(),
        wordList.getCurrentWord(), wordList.getCurrentTrans(), this);
    }
  }

  public void onUnpop() {
    closeConnection();
  }

  private void closeConnection() {
    main.getConnectionManager().closeConnection(wordList);
    wordList = null;
  }

  /**
   * export this database to a Memo.
   */
  private void export() {
    if (ConvertList.export(wordList)) {
      popupModal(new MessageBox("Export", "Exported the words."));
    } else {
      popupModal(new MessageBox("Export", "Could not export the words."));
    }
  }
}