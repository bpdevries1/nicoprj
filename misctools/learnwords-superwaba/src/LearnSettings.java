
/**
 *
 * <p>Title: Settings</p>
 * <p>Description: Settings voor leren: reverse, random, rounds</p>
 * <p>Copyright: Copyright (c) 2002</p>
 * <p>Company: </p>
 * @author Nico de Vreeze
 * @version 1.0
 */
public class LearnSettings {

  /**
   * Ask the words in random order?
   */
  private boolean random = false;

  /**
   * Ask the words reverse, from known language to foreign language?
   */
  private boolean reverse = false;

  /**
   * Show translation automatically after a defined number of seconds?
   */
  private boolean automatic = false;

  /**
   * Use the 'rounds' learning algorithm, or a more sophisticated way with min-
   * and max errors:
   * * while the number of errors is less than the treshold 'minErrors', always ask
   *   a new word.
   * * while the number of errors is bigger than the treshold 'maxErrors', always ask
   *   an old word, which was answered wrong before.
   * * while the number of errors is in between, the chance of an old or new word depends
   *   on the relative distance between the number of erros and min/max.
   */
  private boolean rounds = false; // true;

  /**
   * the minimum treshold for the sophisticated learning system.
   */
  private int minErrors = 0; // start low for testing.

  /**
   * the minimum treshold for the sophisticated learning system.
   */
  private int maxErrors = 10; // start low for testing.

  /**
   * In automatic mode, number of seconds to wait before showing
   * translation.
   */
  private int waitBefore = 5; // want 5, this to test different then after.

  /**
   * In automatic mode, number of seconds to wait after showing
   * translation and thereby defaulting to 'wrong'.
   */
  private int waitAfter = 5;

  public LearnSettings() {

  }

  public boolean isRandom() {
    return random;
  }

  public void setRandom(boolean aRandom) {
    random = aRandom;
  }

  public boolean isReverse() {
    return reverse;
  }

  public void setReverse(boolean aReverse) {
    reverse = aReverse;
  }

  public boolean isAutomatic() {
    return automatic;
  }

  public void setAutomatic(boolean aAutomatic) {
    automatic = aAutomatic;
  }

  public boolean isRounds() {
    return rounds;
  }

  public void setRounds(boolean aRounds) {
    rounds = aRounds;
  }

  public int getMinErrors() {
    return minErrors;
  }

  public void setMinErrors(int aMinErrors) {
    minErrors = aMinErrors;
  }

  public int getMaxErrors() {
    return maxErrors;
  }

  public void setMaxErrors(int aMaxErrors) {
    maxErrors = aMaxErrors;
  }

  public int getWaitBefore() {
    return waitBefore;
  }

  public void setWaitBefore(int aWaitBefore) {
    waitBefore = aWaitBefore;
  }

  public int getWaitAfter() {
    return waitAfter;
  }

  public void setWaitAfter(int aWaitAfter) {
    waitAfter = aWaitAfter;
  }

}