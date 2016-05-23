import java.io.File;
import javax.swing.filechooser.*;

/**
 * Title:        Woordjes leren voor Palm
 * Description:  Woordjes leren voor de Palm met SuperWaba 2.4
 * Copyright:    Copyright (c) 2002
 * Company:
 * @author Nico de Vreeze
 * @version 1.0
 */

public class FileFilterWord extends FileFilter {

// return true if should accept a given file
  public boolean accept(File aFile) {
    if (aFile.isDirectory()) {
      return true;
    }
    String path = aFile.getPath().toLowerCase();
    if (path.endsWith(".wrd")) {
      return true;
    }
    return false;
  }

// return a description of files
  public String getDescription() {
    return "Word file (*.wrd)";
  }

}
