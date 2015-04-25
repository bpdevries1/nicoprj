#include <stdio.h>
#include <string.h>

int main(void) {
    printf("Hello World \n");

    struct NameValue
    {
      char name[50];
      char value[255];
    }; 

    struct NameValue nv = {"name1", "value1"};
    printf("nv.name = %s, value = %s\n", nv.name, nv.value);
    
    struct NameValue config[20];

    strcpy(nv.name, "name1a");
    strcpy(nv.value, "value1a");

    printf("nv.name = %s, value = %s\n", nv.name, nv.value);
    
    strcpy(config[1].name, "namec1");
    strcpy(config[1].value, "valuec1");

    printf("c1.name = %s, value = %s\n", config[1].name, config[1].value);

    //index 0:
    int i = 0;
    strcpy(config[i].name, "namec0");
    strcpy(config[i].value, "valuec0");

    printf("ci.name = %s, value = %s\n", config[i].name, config[i].value);
    
    // config[0] = {"name1", "value1"};
    // config[1] = {"name2", "value2"};
    // config[2] = {"name3", "value3"};

    printf("The end\n");
    return 0;
}

// compiled with: gcc -Wall helloworld.c -o helloworld

