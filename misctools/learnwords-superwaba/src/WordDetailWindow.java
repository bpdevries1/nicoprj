import waba.ui.*;
import waba.sys.*;
// import edits.*;


/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 *
 * @todo reuse multi-line edits, sits in Waba-extension, fails to work on Palm-
 * emulator, does work with Appletviewer.
 */

public class WordDetailWindow extends Window {

  LearnWords main = null;

  Label lbWord = null;
  Label lbTrans = null;

  // MultiEdit edWord = null;
  // MultiEdit edTrans = null;

  Edit edWord = null;
  Edit edTrans = null;

  Button update = null;
  Button close = null;
  // later also previous, next buttons.

  public WordDetailWindow(LearnWords aMain) {

    super("Words detail", NO_BORDER); // with caption and borders

    main = aMain;

    setRect(LEFT, TOP, Settings.screenWidth, Settings.screenHeight);

    lbWord = new Label("Word:");
    lbTrans = new Label("Translation:");

    // edWord = new MultiEdit(0);
    // edTrans = new MultiEdit(0);
    edWord = new Edit();
    edTrans = new Edit();

    update = new Button("Update");
    close = new Button("Close");
    update.setGap(3);
    close.setGap(3);

    add(lbWord, LEFT, TOP);

    add(edWord);
    edWord.setRect(SAME, AFTER, FILL, PREFERRED);
    add(lbTrans, SAME, AFTER);
    add(edTrans);
    edTrans.setRect(SAME, AFTER, FILL, PREFERRED);

    add(update, LEFT, BOTTOM);
    add(close, RIGHT, SAME);
  }

  public void setWordList(String aWordlist) {
    setTitle(aWordlist);
  }

  public void setWord(String aWord) {
    edWord.setText(aWord);
  }

  public void setTrans(String aTrans) {
    edTrans.setText(aTrans);
  }

  public void onEvent(Event event) {
    if (event.type == ControlEvent.PRESSED) {
      if (event.target == update) {
        // nothing yet
      } else if (event.target == close) {
        main.getWindowManager().close(this);
      }
    }
  }

}