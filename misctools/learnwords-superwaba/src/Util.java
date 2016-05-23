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

public class Util {

  /**
   * Boolean to state if we need to compile for palm or Emulator.
   */
  public static final boolean ONPALM = true;
  // public static final boolean ONPALM = false;

  public static final boolean DEBUGMODE = false;
  // public static final boolean DEBUGMODE = true;

  /**
   * File conversion is a bit difficult outside the Waba-applet, so for now
   * keep it in. This boolean to denote if conversion-class needs to be linked.
   * @todo make separate conversion-utility. Or convert a standard Note to a wordlist.
   */
  //public static final boolean INCLUDECONVERT = true;
  public static final boolean INCLUDECONVERT = !ONPALM;

  public static String DBEXTENSION = ".NgDB.DATA";
  public static String DBMETA = "_WordsMeta" + DBEXTENSION;
  public static String DBSTATE = "_WordsState" + DBEXTENSION;
  public static String CHECKSYMBOL = "LearnWords";

  public static final char LF = '\n';
  public static final char TAB = '\t';

  public static void message(String msg) {
    if (DEBUGMODE) {
      if (ONPALM) {
        Vm.debug(msg);
      } else {
        System.err.println(msg);
        System.err.flush();
      }
    }
  }

}