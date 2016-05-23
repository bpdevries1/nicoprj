import waba.ui.*;
import waba.sys.*;

/**
 * <p>Title: Woordjes leren voor Palm</p>
 * <p>Description: Woordjes leren voor de Palm met SuperWaba 2.4</p>
 * <p>Copyright: Copyright (c) 2002</p>
 * <p>Company: </p>
 * @author Nico de Vreeze
 * @version 1.0
 */

public class SettingsWindow extends Window {

  /**
   * ref. to main-window, used for window-manager and also for starting a
   * session.
   */
  private LearnWords main = null;

  /**
   * settings object
   */
  LearnSettings settings = null;

  /**
   * settings editboxes
   */
  Edit edMinErrors = null;
  Edit edMaxErrors = null;
  Edit edWaitBefore = null;
  Edit edWaitAfter = null;

  Button btOk = null;

  public SettingsWindow(LearnWords aMain) {

    super("Settings", NO_BORDER); // with caption and borders
    main = aMain;

    setRect(LEFT, TOP, Settings.screenWidth, Settings.screenHeight);

    edMinErrors = makeLabelEdit("Min Errors:", TOP);
    edMaxErrors = makeLabelEdit("Max errors:", AFTER);
    edWaitBefore = makeLabelEdit("Wait before:", AFTER);
    edWaitAfter = makeLabelEdit("Wait after:", AFTER);

    btOk = new Button("Close");
    btOk.setGap(3);

    add(btOk, RIGHT, BOTTOM);
  }

  private Edit makeLabelEdit(String labelText, int vertPosition) {
    add(new Label(labelText), LEFT, vertPosition);
    Edit edit = new Edit();
    add(edit);
    edit.setRect(LEFT, AFTER, FILL, PREFERRED);
    return edit;
  }

  public void setSettings(LearnSettings aSettings) {
    settings = aSettings;
    edMinErrors.setText(Convert.toString(settings.getMinErrors()));
    edMaxErrors.setText(Convert.toString(settings.getMaxErrors()));
    edWaitBefore.setText(Convert.toString(settings.getWaitBefore()));
    edWaitAfter.setText(Convert.toString(settings.getWaitAfter()));
  }

  /**
   * event handler
   */
  public void onEvent(Event event) {
    if (event.type == ControlEvent.PRESSED) {
      if (event.target == btOk) {
        main.getWindowManager().close(this);
      }
    }
  }

  public void onUnpop() {
    fillSettings();
  }

  /**
   * put settings from editbox to settings object.
   */
  private void fillSettings() {
    settings.setMinErrors(Convert.toInt(edMinErrors.getText()));
    settings.setMaxErrors(Convert.toInt(edMaxErrors.getText()));
    settings.setWaitBefore(Convert.toInt(edWaitBefore.getText()));
    settings.setWaitAfter(Convert.toInt(edWaitAfter.getText()));
  }

}