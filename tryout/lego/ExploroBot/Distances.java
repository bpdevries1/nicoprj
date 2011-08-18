// import java.util.Collections; LeJos doesn't have this one

public class Distances {
  
  private static final int NDISTANCES = 9;

  private int[] distances = new int[NDISTANCES];
  private int ptr_next = 0; // where will the next value be placed in the array.
  
  public Distances(int distance) {
    // setting all values to the same value ensures that the median is correct,
    // and we only need to keep one current pointer.
    for (int i = 0; i < NDISTANCES; i++) {
      distances[i] = distance;
    }
  }
  
  public void add(int distance) {
    distances[ptr_next] = distance;
    ptr_next++;
    if (ptr_next == NDISTANCES) {
      ptr_next = 0; 
    }
  }

/*  
  // sort is not available yet (7-7-2011)
  public int median() {
     // return java.util.Collections.sort((int[])distances.clone())[NDISTANCES / 2];
     return Collections.sort((int[])distances.clone())[NDISTANCES / 2];
  }
*/

  // maybe need to exclude extreme values first.
  public int average() {
    int sum = 0;
    for (int i = 0; i < NDISTANCES; i++) {
      sum += distances[i];
    }
    return sum / NDISTANCES;
  }

}

