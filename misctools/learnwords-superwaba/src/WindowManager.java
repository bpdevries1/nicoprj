import waba.ui.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

public class WindowManager {

  private LearnWords main = null;

  private ListsOverviewWindow listsOverview = null;
  private ListInfoWindow listInfo = null;
  private WordsOverviewWindow wordsOverview = null;
  private WordDetailWindow wrdDetail = null;
  private SettingsWindow wndSettings = null;

  public WindowManager(LearnWords aMain) {
    main = aMain;
  }

  public void openDBOverzicht() {
    checkDBOverzichtWindow();
    main.popupModal(listsOverview);
  }

  /**
   * update previous item in list. Only if this item is nonnull and window
   * is initialised.
   */
  public void updateListsOverview(ListInfoItem item) {
    if ((item != null) && (listsOverview != null)) {
      listsOverview.updateItem(item);
    }
  }

  public void refreshDBOverzicht() {
    checkDBOverzichtWindow();
    listsOverview.refreshItems();
  }

  /**
   * initialize DBOverzichtWindow if it is null
   */
  private void checkDBOverzichtWindow() {
    if (listsOverview == null) {
      listsOverview = new ListsOverviewWindow(main);
    }
  }

  public void showWoordOverzicht(String listname, Window parent) {
    showWoordOverzicht(listname, -1, parent);
  }

  public void showWoordOverzicht(String listname, int currentPos, Window parent) {
    Util.message("showWoordOvz: start");
    if (wordsOverview == null) {
      wordsOverview = new WordsOverviewWindow(main);
    }
    wordsOverview.setList(listname);
    parent.popupModal(wordsOverview);
    if (currentPos != -1) {
      wordsOverview.setCurrentPos(currentPos);
    }
  }

  public void showListInfo(String listname, Window parent) {
    Util.message("WinMan: showListinfo: start: " + listname);
    if (listInfo == null) {
      listInfo = new ListInfoWindow(main);
    }
    listInfo.setList(listname);
    parent.popupModal(listInfo);
  }

  public void showWordDetail(String wordlist, String word, String trans, Window parent) {
    Util.message("WinMan: showWoordDetail: start");
    if (wrdDetail == null) {
      wrdDetail = new WordDetailWindow(main);
    }
    wrdDetail.setWordList(wordlist);
    wrdDetail.setWord(word);
    wrdDetail.setTrans(trans);
    // main.popupModal(wrdDetail);
    parent.popupModal(wrdDetail);
  }

  public void showSettings(LearnSettings settings, Window parent) {
    if (wndSettings == null) {
      wndSettings = new SettingsWindow(main);
    }
    wndSettings.setSettings(settings);
    parent.popupModal(wndSettings);
  }

  public void closeAllPopups() {
    Window wnd = null;
    wnd = Window.getTopMost();
    while (wnd != main) {
      Util.message("Closing popup: " + wnd);
      close(wnd);
      wnd = Window.getTopMost();
    }
  }

  /**
   * close a popup-window. Care must be taken that no 2 popups share the same
   * parent!
   */
  public void close(Window wnd) {
    wnd.unpop();
  }

}