import waba.fx.*;
import waba.sys.*;
import waba.util.*;
import waba.ui.*;
import waba.io.*;

/** @todo Call resetTimer and killTimer */

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 * main-class: main-screen, userinterface, menu.
 */
public class LearnWords extends MainWindow {

  private final static String SHOWTEXT = "Show";
  private final static String CORRECTTEXT = "Correct";
  private final static String FALSETEXT = "Wrong";

  public final static int STATE_IDLE = 0; // no file loaded
  public final static int STATE_SHOWWORD = 1; // word shown, trans not yet
  public final static int STATE_SHOWTRANS = 2; // trans also shown
  public final static int STATE_FINISHED = 3; // finished learning.

  private int state = STATE_IDLE;

  private LearnSettings settings = null;

  private LearnSession learnSession = null;

  /**
   * window manager used for opening and closing popups
   */
  private WindowManager windowManager = null;

  /**
   * connection manager used so max. 1 connection to a database is created.
   * on Palm, no more than 1 connection to a DB can be open.
   */
  private ConnectionManager connectionManager = null;

  /**
   * Helper object to control timer events for automatic learning.
   */
  private LearnTimer learnTimer = null;

  // Menu-bar stuff
  MenuBar mbar = null;
  String mnuFile[] = {"Learn", "Open list..." , "Again", "-", "?Reverse", "?Random", "?Automatic", "-", "Exit"};
  String mnuManage[] = {"Manage", "Refresh lists", "Import memo", "-", "Settings..."};
  String mnuExtra[] = {"Extra", "Convert..."};

  private static final int MNU_OPEN = 1;
  private static final int MNU_AGAIN = 2;
  private static final int MNU_REV = 4;
  private static final int MNU_RANDOM = 5;
  private static final int MNU_AUTOMATIC = 6;
  private static final int MNU_EXIT = 8;

  private static final int MNU_REFRESH = 101;
  private static final int MNU_IMPORTMEMO = 102;
  private static final int MNU_SETTINGS = 104;

  private static final int MNU_CONVERT = 201;

  // User interface widgets

  // word +translation
  Label wordlabel = null;
  Label translabel = null;
  Edit word = null;
  Edit trans = null;

  // Buttons. Cannot use enabled/disabled buttons, is buggy in Waba.
  Button showButton = null;
  Button correctButton = null;
  Button falseButton = null;

  Button infoButton = null;
  Button listButton = null;
  Button detailButton = null;

  // checkbox for overriding hardware buttons.
  Check cbButtons = null;

  // Statusbar
  Label roundlabel = null;
  Label round = null;
  Label totallabel = null;
  Label total = null;
  Label correctlabel = null;
  Label correct = null;
  Label wronglabel = null;
  Label wrong = null;

  public LearnWords() {
    super("Learn Words", TAB_ONLY_BORDER);
  }

  public void onStart() {
    makeUI();

    setInterceptKeys(true);

    settings = new LearnSettings();
    learnSession = new LearnSession(settings);
    windowManager = new WindowManager(this);
    connectionManager = new ConnectionManager(learnSession.getCurrentList());
    learnTimer = new LearnTimer(this, settings);

    if (learnSession.loadState()) {
      setTitleToList(learnSession.getCurrentListName());
      updateStatusBar();
      updateMenu();
      showWord();
    }
  }

  private void setInterceptKeys(boolean intercept) {
    if (intercept) {
      // set intercept hard keys
      Vm.interceptSystemKeys(Vm.SK_HARD1 | Vm.SK_HARD2 | Vm.SK_HARD3 | Vm.SK_HARD4);
    } else {
      Vm.interceptSystemKeys(0); // no interception
    }
    cbButtons.setChecked(intercept);
  }

  /**
   * make user interface
   *
   */
  private void makeUI() {
    if (Util.INCLUDECONVERT) {
      setMenuBar(mbar = new MenuBar(new String[][]{mnuFile, mnuManage, mnuExtra}));
    } else {
      setMenuBar(mbar = new MenuBar(new String[][]{mnuFile, mnuManage}));
    }

    // word + translation
    add(wordlabel = new Label("Word:"), LEFT, TOP);
    add(word = new Edit());
    word.setRect(LEFT, AFTER, FILL, PREFERRED);

    add(translabel = new Label("Trans:"), LEFT, AFTER); // 5 pixels tussen widgets?
    add(trans = new Edit());
    trans.setRect(LEFT, AFTER, FILL, PREFERRED);

    // Buttons
    add(showButton = new Button(SHOWTEXT));
    showButton.setGap(3);
    showButton.setRect(LEFT, AFTER + 10, FILL, PREFERRED);
    add(correctButton = new Button(CORRECTTEXT));
    correctButton.setGap(3);
    correctButton.setRect(LEFT, AFTER, 80, PREFERRED);
    add(falseButton = new Button(FALSETEXT));
    falseButton.setGap(3);
    falseButton.setRect(AFTER, SAME, FILL, PREFERRED);

    add(infoButton = new Button("Info"));
    infoButton.setGap(3);
    infoButton.setRect(LEFT, AFTER + 10, PREFERRED, PREFERRED);

    add(listButton = new Button("List"));
    listButton.setGap(3);
    listButton.setRect(AFTER, SAME, PREFERRED, PREFERRED);

    add(detailButton = new Button("Detail"));
    detailButton.setGap(3);
    detailButton.setRect(AFTER, SAME, PREFERRED, PREFERRED);

    // checkbox for override hardware buttons, default on.
    add(cbButtons = new Check("Buttons"));
    cbButtons.setChecked(true);
    cbButtons.setRect(RIGHT, SAME, PREFERRED, PREFERRED);

    // statusbar
    add(totallabel = new Label("Total:"), LEFT, BOTTOM);
    add(total = new Label("          "), AFTER + 5, SAME);
    add(wronglabel = new Label("Wrong:"), 80, SAME);
    add(wrong = new Label("          "), AFTER + 5, SAME);

    add(roundlabel = new Label("Round:"), LEFT, BEFORE);
    add(round = new Label("      "), AFTER + 5, SAME);
    add(correctlabel = new Label("Correct:"), 80, SAME);
    add(correct = new Label("          "), AFTER + 5, SAME);
  }

  public void openWordList(String listname) {
    if ((listname != null) && (listname.compareTo("") != 0)) {
      ListInfoItem prevItem = learnSession.readWords(listname);
      windowManager.updateListsOverview(prevItem);
      setTitleToList(listname);
      updateMenu();
      updateStatusBar();
      startLearning();
    }

  }

  public WindowManager getWindowManager() {
    return windowManager;
  }

  public ConnectionManager getConnectionManager() {
    return connectionManager;
  }

  /**
   * set title
   */
  private void setTitleToList(String listname) {
    // lblListname.setText(listname);
    setTitle(listname);
  }

  private void learnAgain() {
    startLearning();
  }

  private void toggleReverse() {
    learnSession.toggleReverse();
    updateMenu();
    startLearning();
  }

  private void toggleRandom() {
    learnSession.toggleRandom();
    updateMenu();
    startLearning();
  }

  private void toggleAutomatic() {
    learnSession.toggleAutomatic();
    /** @todo switch on/off timer */
    if (learnSession.isAutomatic()) {
      if (!learnTimer.startTimer(state)) {
        // timer start failed, toggleAutomatic again.
        learnSession.toggleAutomatic();
      }
    } else {
      learnTimer.stopTimer();
    }
    updateMenu();
  }

  private void startLearning() {
    learnSession.reset();
    startRound();
  }

  /**
   * evt. later toonwoord hier niet aanroepen, maar los.
   */
  private void startRound() {
    learnSession.startRound();
    showWord();
  }

  private void showWord() {
    if (learnSession.isRoundFinished()) {
      if (learnSession.getCountWrong() > 0) {
        startRound();
      } else {
        if (learnSession.isAutomatic()) {
          learnSession.toggleAutomatic();
          learnTimer.stopTimer();
          updateMenu();
        }
        popupModal(new MessageBox("Finished", "Finished learning the words."));
        word.setText("");
        trans.setText("");
        state = STATE_FINISHED;
      }
    } else {
      learnSession.nextWord();
      String woord = learnSession.getCurrentWord();
      word.setText(woord);
      trans.setText("");
    }
    updateStatusBar();
    state = STATE_SHOWWORD;
  }

  public void showTrans() {
    String strTrans = learnSession.getCurrentTrans();
    trans.setText(strTrans);
    state = STATE_SHOWTRANS;
    learnTimer.resetTimer(state);
  }

  public void cmdCorrect() {
    learnSession.wordCorrect();
    showWord();
    learnTimer.resetTimer(state);
  }

  public void cmdFalse() {
    learnSession.wordWrong();
    showWord();
    learnTimer.resetTimer(state);
  }

  private void listInfo() {
    // Util.message("main.listinfo: start");
    windowManager.showListInfo(learnSession.getCurrentListName(), this);
  }

  private void listWords() {
    // Util.message("main.listwords: start");
    windowManager.showWoordOverzicht(learnSession.getCurrentListName(),
        learnSession.getCurrentRecord(), this);

  }

  private void showWordDetail() {
    // Util.message("main.showdetail: start");
    windowManager.showWordDetail(learnSession.getCurrentListName(),
       learnSession.getCurrentWord(), learnSession.getCurrentTrans(), this);
  }

  /**
   * update statusbar, possible to make more efficient.
   */
  private void updateStatusBar() {
    round.setText(""+learnSession.getRound());
    total.setText(""+learnSession.getCountRound());
    correct.setText(""+learnSession.getCountCorrect());
    wrong.setText(""+learnSession.getCountWrong());
  }

  /**
   * set checked menu-items reverse and random.
   */
  private void updateMenu() {
    mbar.setChecked(MNU_REV, learnSession.isReverse());
    mbar.setChecked(MNU_RANDOM, learnSession.isRandom());
  }

  /**
   * Called by the system to pass events to the application.
   * check state and change it before calling the approp. methods, which
   * can change the state if needed.
   */
   public void onEvent(Event event) {
      if (event.type == ControlEvent.PRESSED) {
         if (event.target == showButton) {
            if (state == STATE_SHOWWORD) {
              showTrans();
            }
         } else if (event.target == correctButton) {
            if (state == STATE_SHOWTRANS) {
              cmdCorrect();
            }
         } else if (event.target == falseButton) {
            if (state == STATE_SHOWTRANS) {
              cmdFalse();
            }
         } else if (event.target == infoButton) {
            if (state != STATE_IDLE) {
              listInfo();
            }
         } else if (event.target == listButton) {
            if (state != STATE_IDLE) {
              listWords();
            }
         } else if (event.target == detailButton) {
            if ((state == STATE_SHOWWORD) || (state == STATE_SHOWTRANS)) {
              showWordDetail();
            }
         } else if (event.target == cbButtons) {
            // has checkbox-state already changed here? assume it has.
            setInterceptKeys(cbButtons.getChecked());
         } else {
            Util.message("PRESSED.Target: " + event.target);
         }
      } else if (event.type == ControlEvent.WINDOW_CLOSED) {
        if (event.target == mbar) {
          int sel = mbar.getSelectedMenuItem();
          if (sel == MNU_OPEN) {
            windowManager.openDBOverzicht();
          } else if (sel == MNU_AGAIN) {
            if (state != STATE_IDLE) {
              learnAgain();
            }
          } else if (sel == MNU_REV) {
            if (state != STATE_IDLE) {
              toggleReverse();
            }
          } else if (sel == MNU_RANDOM) {
            if (state != STATE_IDLE) {
              toggleRandom();
            }
          } else if (sel == MNU_AUTOMATIC) {
            if (state != STATE_IDLE) {
              toggleAutomatic();
            }
          } else if (sel == MNU_EXIT) {
            exit(0);
          } else if (sel == MNU_REFRESH) {
            MetaData.refreshDBs();
            windowManager.refreshDBOverzicht();
          } else if (sel == MNU_IMPORTMEMO) {
            importMemo();
          } else if (sel == MNU_SETTINGS) {
            windowManager.showSettings(settings, this);
          } else if (Util.INCLUDECONVERT && (sel == MNU_CONVERT)) {
            ConvertList.convert(this);
            MetaData.refreshDBs();
          } else {
            Util.message("Menu: " + sel);
          }
        } else {
           Util.message("CLOSED.Target: " + event.target);
        }
      } else if (event.type == KeyEvent.KEY_PRESS) {
        KeyEvent ke = (KeyEvent)event;
        // only use 2 buttons, both work as Show if state == SHOWWORD, otherwise
        // left works as Correct and right one as Wrong.
        if ((ke.key == IKeys.HARD1) || (ke.key == IKeys.HARD3)) { // Agenda/Todo, used for Show and Correct
          if (state == STATE_SHOWWORD) {
            showTrans();
          } else if (state == STATE_SHOWTRANS) {
            cmdCorrect();
          }
        } else if ((ke.key == IKeys.HARD2) || (ke.key == IKeys.HARD4)) { // Address/Note, used for Show and Wrong
          if (state == STATE_SHOWWORD) {
            showTrans();
          } else if (state == STATE_SHOWTRANS) {
              cmdFalse();
          }
/*
        } else if (ke.key == IKeys.HARD3) { // Todo, used to switch off intercept hardware keys
          setInterceptKeys(false);
*/
        }
      } else if (event.type == ControlEvent.TIMER) {
        learnTimer.incrCounter();
      } else {
        // Util.message("EVENT: " + event.type + " - " + event);
      }
   }

  /**
   * save state, so next time continue where we left.
    */
  public void onExit() {
    Util.message("Appl. exit");
    if ((state == STATE_SHOWWORD) || (state == STATE_SHOWTRANS)) {
      learnSession.saveState();
    } else {
      learnSession.clearState();
    }
    if (state != STATE_IDLE) {
      learnSession.saveStatistics();
    }
    MetaData.closeMeta();
  }

  private void importMemo() {
    String dbname = ConvertList.importMemo(this);
    if (dbname != null) {
      popupModal(new MessageBox("Import", "Imported: " + dbname));
    } else {
      popupModal(new MessageBox("Import", "Could not import the words."));
    }
  }
}
