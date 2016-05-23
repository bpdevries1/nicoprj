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

public class ListInfoWindow extends Window {

  /**
   * ref. to main-window, used for window-manager and also for starting a
   * session.
   */
  private LearnWords main = null;
  private String listname = null;
  private ListInfoItem infoItem = null;
  private Label lbDate = null;
  private Edit edDate = null;
  private Label lbRounds = null;
  private Edit edRounds = null;
  private Label lbFinished = null;
  private Edit edFinished = null;
  private Label lbReverse = null;
  private Edit edReverse = null;
  private Label lbRandom = null;
  private Edit edRandom = null;
  private Label lbNotes = null;
  private Edit edNotes = null; // @todo: use multiline.

  Button learn = null;
  Button close = null;

  public ListInfoWindow(LearnWords aMain) {
    super("List info", NO_BORDER); // with caption and borders
    main = aMain;

    setRect(LEFT, TOP, Settings.screenWidth, Settings.screenHeight);

    add(lbDate = new Label("Date:"), LEFT, TOP);
    add(edDate = new Edit()); edDate.setRect(AFTER, SAME, FILL, PREFERRED);
    add(lbRounds = new Label("Rounds:"), LEFT, AFTER);
    add(edRounds = new Edit()); edRounds.setRect(AFTER, SAME, FILL, PREFERRED);
    add(lbFinished = new Label("Finished:"), LEFT, AFTER);
    add(edFinished = new Edit()); edFinished.setRect(AFTER, SAME, FILL, PREFERRED);
    add(lbReverse = new Label("Reverse:"), LEFT, AFTER);
    add(edReverse = new Edit()); edReverse.setRect(AFTER, SAME, FILL, PREFERRED);
    add(lbRandom = new Label("Random:"), LEFT, AFTER);
    add(edRandom = new Edit()); edRandom.setRect(AFTER, SAME, FILL, PREFERRED);
    add(lbNotes = new Label("Notes:"), LEFT, AFTER);
    add(edNotes = new Edit()); edNotes.setRect(AFTER, SAME, FILL, PREFERRED);

    learn = new Button("Select");
    close = new Button("Close");
    learn.setGap(3);
    close.setGap(3);

    add(learn, LEFT, BOTTOM);
    add(close, RIGHT, SAME);

  }

  public void setList(String aListname) {
    listname = aListname;

    infoItem = MetaData.getInfoItem(aListname);
    setTitle(aListname);
    if (infoItem.date != null) {
      edDate.setText(infoItem.date.toString());
      edRounds.setText("" + infoItem.nrounds);
      edFinished.setText(infoItem.finished?"Yes":"No");
      edReverse.setText(infoItem.reverse?"Yes":"No");
      edRandom.setText(infoItem.random?"Yes":"No");
    } else {
      edDate.setText("");
      edRounds.setText("");
      edFinished.setText("");
      edReverse.setText("");
      edRandom.setText("");
    }
    edNotes.setText(infoItem.notes);
  }

  /**
   * event handler
   */
  public void onEvent(Event event) {
    if (event.type == ControlEvent.PRESSED) {
      if (event.target == learn) {
        learnList();
      } else if (event.target == close) {
        closeWindow();
      }
    }
  }

  private void learnList() {
    saveNotes();
    main.getWindowManager().closeAllPopups();
    main.openWordList(listname);
  }

  private void closeWindow() {
    saveNotes();
    main.getWindowManager().close(this);
  }

  private void saveNotes() {
    infoItem.notes = edNotes.getText();
    MetaData.saveItem(infoItem);
  }

}