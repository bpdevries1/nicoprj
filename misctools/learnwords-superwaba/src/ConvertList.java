import waba.io.Catalog;
import waba.io.ResizeStream;
import waba.io.DataStream;
import java.io.BufferedReader;
import java.io.FileReader;
import waba.ui.*;
import superwaba.ext.palm.io.builtin.Memo;

import javax.swing.*;
import java.awt.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

public class ConvertList extends MainWindow {

  private static final String MEMOPREFIX = "Words: ";

/*
  public static void main(String[] args) {
    convert(args[0], args[1]);
  }
*/

  public static void convert(Object parent) {
/*
    Util.message("Converting IT...");
    convert("IT-Basic.wrd", "IT-Basic");
    Util.message("...converted");
*/

    // makeMemo();

//    importMemo(parent);

/*
    System.err.println("Opening chooser");
    System.err.flush();
    String cwd = System.getProperty("user.dir");
    JFileChooser chooser = new JFileChooser(cwd);
    chooser.setFileFilter(new FileFilterWord());
    chooser.setDialogTitle("Open Word file2");
    Util.message("Showing chooser for convert");

    int returnVal = chooser.showOpenDialog(null);
    if (returnVal == JFileChooser.APPROVE_OPTION) {
      String wordfile = chooser.getSelectedFile().getName();
      Util.message("Wordfile: " + wordfile);
      int p = wordfile.indexOf(".");
      convert(wordfile, wordfile.substring(0, p));
    } else {
      Util.message("User pressed cancel");
    }
*/
  }

/*
  private static void convert(String fromfile, String todatabase) {
    try {
      String wordLine = null;
      String word = null;
      String trans = null;
      int p = 0;
      Catalog c = new Catalog(todatabase + Util.DBEXTENSION, Catalog.CREATE);
      if (c.isOpen()) {
        removeAll(c);
        ResizeStream rs = new ResizeStream(c, 512);
        DataStream ds = new DataStream(rs);

        BufferedReader in = new BufferedReader(new FileReader(fromfile));
        while ((wordLine = in.readLine()) != null) {
          p = wordLine.indexOf("\t");
          if (p > 0) {
            word = wordLine.substring(0, p);
            trans = wordLine.substring(p + 1);
            rs.startRecord();
            ds.writeString(word);
            ds.writeString(trans);
            rs.endRecord();
          }
        } // while
        in.close();

        ds.close();
        rs.close();
        c.close();
      } else {
        // System.out.println("DB could not be created");
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
  }
*/

  /**
   * Convert a memo created on the palm to a LearnWords database.
   * Overwrites an existing database.
   * @todo refactor code with convert-method.
   */
  public static String importMemo(Object parent) {
    Memo memo = Memo.findMemo(MEMOPREFIX, false);
    if (memo != null) {
      MemoReader memoReader = new MemoReader(memo);
      String header = memoReader.readLine();
      String todatabase = header.substring(MEMOPREFIX.length());
      Catalog c = new Catalog(todatabase + Util.DBEXTENSION, Catalog.CREATE);
      if (c.isOpen()) {
        removeAll(c);
        ResizeStream rs = new ResizeStream(c, 512);
        DataStream ds = new DataStream(rs);

        // BufferedReader in = new BufferedReader(new FileReader(fromfile));
        // while ((wordLine = in.readLine()) != null) {
        String wordLine = null;
        String word = null;
        String trans = null;
        int p = 0;
        while ((wordLine = memoReader.readLine()) != null) {
          p = wordLine.indexOf("\t");
          if (p > 0) {
            word = wordLine.substring(0, p);
            trans = wordLine.substring(p + 1);
            rs.startRecord();
            ds.writeString(word);
            ds.writeString(trans);
            rs.endRecord();
          }
        } // while
        // in.close();

        ds.close();
        rs.close();
        c.close();
        return todatabase;
      } else {
        // System.out.println("DB could not be created");
        return null;
      }
    } else {
      return null;
    }
  }

  public static boolean export(WordList wordList) {
    StringBuffer buf = new StringBuffer();
    buf.append(MEMOPREFIX);
    buf.append(wordList.getCurrentListname());
    int n = wordList.getCount();
    for (int i = 0; i < n; i++) {
      buf.append(Util.LF);
      buf.append(wordList.getWordTransExport(i));
    }

    Memo memo = new Memo();
    memo.text = buf.toString();
    Memo.addMemo(memo);

    return true;
  }

  /**
   * remove all records from a database/catalog
   * @param c Catalog
   */
  private static void removeAll(Catalog cat) {
    int n = cat.getRecordCount();
    for (int i = n - 1; i >= 0; i--) {
      cat.setRecordPos(i);
      cat.deleteRecord();
    }
  }

  private static void makeMemo() {
    Memo memo = new Memo();
    memo.text = "Words: IT Extra" + Util.LF + "Palabra 1" + Util.TAB + "Word 1" +
    Util.LF + "Palabra 2" + Util.TAB + "Word 2";
    Memo.addMemo(memo);
  }

}