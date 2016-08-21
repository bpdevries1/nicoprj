#include <stdio.h>
#include <string.h>


#if defined(__STDC__)
# if __STDC_VERSION__ >= 199901L
# define VERSION "C99 or greater"
# elif __STDC_VERSION__ >= 199409L
# define VERSION "C89 with Amendment 1"
# else
# define VERSION "C89"
# endif
#else
# define VERSION "Pre-C89"
#endif

// [2016-08-20 21:46] Dit geheel geeft hier C89, lijkt vrij oud.
// [2016-08-20 21:48] Bij Vugen ook C89, dat kan dan wel weer kloppen.

/*
  Lijkt allemaal nog niet zo gemakkelijk, zoals verwacht. Opties:
  * versies van functies met 2,3,4 params:
    - rb_log_always2("tekst met %d", intvar); // dan vars goed door kunnen geven.
    * zoek in ylib etc.
      - op #define en vooral ...


 */


// some tests with macro's, goal is varargs without C99 varargs, not available in VuGen.
#define CONST1 42
#define PLUS42(x) (x+42)

// should be something with adding/removing parens...
// calling the function is most important, implementation: anything that works!
// so want to do both:
// test_vararg(12); // default second var = 0.
// test_vararg(12,3);
// and also with strings, like printf.
// existing sprintf etc don't mean any guarantees: could be implemented in assembler or something else that isn't programmer/user reachable.

// idea is that varargs are scooped up in one list argument, like args in Tcl.
// #define test_vararg(x,y) test_vararg_fn((x, y))

int test_vararg_fn1(int x, int y) {
    return x+y;
}

int test_vararg_fn2(int* x) {
    // assume array has 2 elements
    return x[0] + x[1];
}

// Dit geheel werkt, maar dus wel wat met __VA_ARGS__
// [2016-08-20 20:27] Dit werkt niet in vugen. Wel een stdarg.h gevonden, maar geeft compileer fouten.
int test_vararg_fn3(const int x, const int y) {
    return x+y;
}
#define test_vararg_macro(X, Y, ...) test_vararg_fn3(X, Y)
#define test_vararg(...) test_vararg_macro(__VA_ARGS__, 0)

// in functies ook de ... gebruiken? [2016-08-20 17:29] ja, hier wel.
int test_vararg_fn4(const int x, const int y, ...) {
    return x+y;
}
#define test_vararg4(...) test_vararg_fn4(__VA_ARGS__, 0)

// Als dit in Vugen (en op LG!) ook werkt, dan testen met string (char*) arguments, en
// ook of params doorgegeven kunnen worden aan sprintf e.d.

// vergelijkbaar:
// #define JUST3(a, b, c, ...) (a), (b), (c)
// #define FUNC(...) func(JUST3(__VA_ARGS__, 0, 0))
// Now FUNC(x) expands to func((x), (0), (0)), FUNC(x,y) expands to func((x), (y), (0)), etc.

// uitleg over stdarg.h - deze ook zelf toe te voegen? Of ook een stukje code nodig?
// https://www.utdallas.edu/~rsv031000/vrk_1/Optional_Arguments_in_C.html

int main(void) {
    int ar[2];
    int ar2[2] = {12,21};
    int *arp1;
    // int *arp2;
    printf("Hello World \n");
    printf("Constant (macro): %d\n", CONST1);
    printf("PLUS42(12): %d\n", PLUS42(12));
    printf("test_vararg_fn1(1,2): %d\n", test_vararg_fn1(1,2));
    ar[0] = 12;
    ar[1] = 23;
    printf("test_vararg_fn2(ar): %d\n", test_vararg_fn2(ar));
    printf("test_vararg_fn2(ar2): %d\n", test_vararg_fn2(ar2));

    arp1 = ar2;
    printf("test_vararg_fn2(arp1): %d\n", test_vararg_fn2(arp1));

    //    arp2 = (int*)({21,21});
    // printf("test_vararg_fn2(arp2): %d\n", test_vararg_fn2(arp2));

    printf("test vararg3(12): %d\n", test_vararg(12));
    printf("test vararg3(12,13): %d\n", test_vararg(12,13));
    
    printf("test vararg4(112): %d\n", test_vararg4(112));
    printf("test vararg4(112,13): %d\n", test_vararg4(112,13));
    // deze hieronder gaat niet, __VA_ARGS__ moet wel wat bevatten.
    // printf("test vararg4(): %d\n", test_vararg4());

    printf(VERSION);

    
    printf("\nThe end\n");
    return 0;
}

// compiled with: gcc -Wall <file>.c -o <file>


