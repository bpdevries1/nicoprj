import waba.ui.*;
import waba.sys.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

public class ListsOverviewWindow extends Window {

  LearnWords main = null;

  ListBox dbs = null;
  Button select = null;
  Button showInfo = null;
  Button showWoordOvz = null;
  Button close = null;

  public ListsOverviewWindow(LearnWords aMain) {
    super("Lists Overview", NO_BORDER); // with caption and borders
    main = aMain;

    setRect(LEFT, TOP, Settings.screenWidth, Settings.screenHeight);

    dbs = new ListBox();
    select = new Button("Select");
    showInfo = new Button("Info");
    showWoordOvz = new Button("Words");
    close = new Button("Close");
    select.setGap(3);
    showInfo.setGap(3);
    showWoordOvz.setGap(3);
    close.setGap(3);

    add(select, LEFT, BOTTOM);
    add(showInfo, AFTER, SAME);
    add(showWoordOvz, AFTER, SAME);
    add(close, RIGHT, SAME);

    add(dbs);
    dbs.setRect(LEFT, TOP, FILL, this.getClientRect().height - select.getPreferredHeight());

    refreshItems();
  }

  public void refreshItems() {
    dbs.removeAll();
    int n = MetaData.getCountDBs();
    for (int i = 0; i < n; i++) {
      dbs.add(MetaData.getListBoxItem(i));
    }
  }

  public void updateItem(ListInfoItem item) {
    if (item.metaIndex < dbs.size()) {
      dbs.setItemAt(item.metaIndex, item.label);
    }
  }


  public void onEvent(Event event) {
    if (event.type == ControlEvent.PRESSED) {
      if (event.target == select) {
        openSelectedLijst();
      } else if (event.target == showInfo) {
        openSelectedInfo();
      } else if (event.target == showWoordOvz) {
        openSelectedWoordOverzicht();
      } else if (event.target == close) {
        main.getWindowManager().close(this);
      }
    }
  }

  private void openSelectedLijst() {
    int idx = dbs.getSelectedIndex();
    if (idx != -1) {
      ListInfoItem item = MetaData.readInfoItem(idx, null);
      main.getWindowManager().closeAllPopups();
      main.openWordList(item.listname);
    }
  }

  private void openSelectedWoordOverzicht() {
    int idx = dbs.getSelectedIndex();
    if (idx != -1) {
      ListInfoItem item = MetaData.readInfoItem(idx, null);
      main.getWindowManager().showWoordOverzicht(item.listname, this);
    }
  }

  private void openSelectedInfo() {
    int idx = dbs.getSelectedIndex();
    if (idx != -1) {
      ListInfoItem item = MetaData.readInfoItem(idx, null);
      main.getWindowManager().showListInfo(item.listname, this);
    }
  }

}