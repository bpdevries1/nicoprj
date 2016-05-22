import waba.ui.*;

/**
 * <p>Title: Woordjes leren voor Palm</p>
 * <p>Description: Woordjes leren voor de Palm met SuperWaba 2.4</p>
 * <p>Copyright: Copyright (c) 2002</p>
 * <p>Company: </p>
 * @author Nico de Vreeze
 * @version 1.0
 */

/**
 *
 * <p>Title: LearnTimer</p>
 * <p>Description: Wrapper around Timer for automatic learning</p>
 * <p>Copyright: Copyright (c) 2003</p>
 * <p>Company: </p>
 * @author Nico de Vreeze
 * @version 1.0
 */
public class LearnTimer {

  /**
   * Reference to main window.
   */
  LearnWords main = null;

  /**
   * Timer object, dynamically created and destroyed.
   */
  Timer timer = null;

  /**
   * settings with time to wait before and after showing translation.
   */
  LearnSettings settings = null;

  /**
   * State that the learnsession is in, only SHOWWORD and SHOWTRANS are
   * relevant here.
   */
  private int state = 0;

  /**
   * Counter to count how many seconds have been waited after last user
   * action.
   */
  private int counter = 0;

  public LearnTimer(LearnWords aMain, LearnSettings aSettings) {
    main = aMain;
    settings = aSettings;
  }

  /**
   * start the timer.
   * @param newState
   * @return true if succeeded, and
   */
  public boolean startTimer(int newState) {
    if ((newState == LearnWords.STATE_SHOWWORD) || (newState == LearnWords.STATE_SHOWTRANS)) {
      if (timer == null) {
        timer = main.addTimer(1000);
        Util.message("started timer");
      }
      resetTimer(newState);
      return true;
    } else {
      return false;
    }
  }

  public void stopTimer() {
    if (timer != null) {
      main.removeTimer(timer);
      timer = null;
    }
  }

  /**
   * Reset the timer if user pressed a button.
   * When learnsession is finished, then
   * user should call stopTimer.
   * @param newState
   */
  public void resetTimer(int newState) {
    state = newState;
    counter = 0;
  }

  /**
   * increase counter by 1 second. If treshold is reached, then call
   * the appropriate method in LearnWords, sort of a callback.
   */
  public void incrCounter() {
    Util.message("timer counter++");
    counter++;
    if (state == LearnWords.STATE_SHOWWORD) {
      // only word is shown, look at waitBefore
      if (counter >= settings.getWaitBefore()) {
        main.showTrans();
      }
    } else if (state == LearnWords.STATE_SHOWTRANS) {
      if (counter >= settings.getWaitAfter()) {
        main.cmdFalse();
      }

    }
  }

}