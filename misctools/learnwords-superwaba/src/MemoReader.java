import superwaba.ext.palm.io.builtin.Memo;

/**
 * <p>Title: Woordjes leren voor Palm</p>
 * <p>Description: Woordjes leren voor de Palm met SuperWaba 2.4</p>
 * <p>Copyright: Copyright (c) 2002</p>
 * <p>Company: </p>
 * @author Nico de Vreeze
 * @version 1.0
 */

public class MemoReader {

  private Memo memo;
  private String memoBody;
  private int memoSize;
  private int indxInMemo;

  public MemoReader(Memo aMemo) {
    memo = aMemo;
    memoBody = memo.text;
    memoSize = memoBody.length();
    indxInMemo = 0;
  }

   public String readLine()
   {
      String    s1 = "";
      int       i;

      if (indxInMemo > memoSize)
         return null;

      i = memoBody.indexOf('\n', indxInMemo);

      if (-1 == i)      // not found return till end of memo
         i = memoSize;

      s1 = memoBody.substring(indxInMemo, i);
      indxInMemo = i + 1;

      return s1;
   }

}