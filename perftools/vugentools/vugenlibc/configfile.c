/* 
usage:
struct NameValue *config;

config = config_read("pat.config");
host = config_get_string(config, "host", "wwwpat.farmersconnect.org");

config is a linked list of name/value pairs.

*/

struct NameValue
 {
   char *name;
   char *value;
   struct NameValue *next;
 };
 
// remove spaces from beginning and end of string. Put result in buf.
// 21-4-2015 tested also with empy string and string with only spaces.
char* strtrim(char* buf, char* str) {
    char *p1, *p2;
    p1 = str;
    while (p1[0] == ' ') {p1++;} // if empty or only spaces, stops at end of string (0-byte).
    p2 = str + strlen(str) - 1; // point to last char of str
    while ((p2 >= p1) && (p2[0] == ' ')) {p2--;}
    strncpy(buf, p1, p2-p1+1);
    buf[p2-p1+1] = 0;
    return buf;
}

struct NameValue* config_read(char* configfile) {
    long file_stream;
    struct NameValue *config = NULL, *curr = NULL;
    char line[255];
    char *p1, *p2;
    char nm[50], val[255]; // temp vars, allocate once with array.
    
    if ((file_stream = fopen(configfile, "r")) == NULL ) {
        lr_output_message("Cannot open %s", configfile);
        return NULL;
    }
    while (!feof(file_stream)) {
        // fgets reads including following newline.
        if (fgets(line, 254, file_stream) == NULL) {
            // error or end of file -> stop reading.
            break;
        }
        p1 = (char *)strchr(line, '#');
        if (p1 == line) {
            // '#' found at first position, continue
            continue;
        }
        p1 = (char *)strchr(line, '=');
        if (p1 == NULL) {
            //    No '=' found, ignore line.
            continue;
        } 
        p2 = (char *)strchr(p1, '\n'); // of '\r'?
        if (p2 == NULL) {
            lr_output_message("No newline found, possibly last line");
            p2 = p1 + strlen(p1); // set pointer to end of string, same place as where newline would be.
        } else {
            // nothing, p2 points to end-of-string (one beyond last char).
        }
        strncpy(nm, line, p1 - line);
        nm[p1 - line] = 0;
        strncpy(val, p1+1, p2 - (p1+1));
        val[p2 - (p1+1)] = 0;
//        lr_output_message("%d: nm: \"%s\", val: \"%s\"", i, nm, val); // from \n to end?

        if (config == NULL) {
            config = (struct NameValue*)malloc(sizeof(struct NameValue));
            curr = config;
        } else {
            curr->next = (struct NameValue*)malloc(sizeof(struct NameValue));
            curr = curr->next;
        }
        curr->next = NULL;
        curr->name = (char*)malloc(strlen(nm)+1);
        curr->value = (char*)malloc(strlen(val)+1);
        strtrim(curr->name, nm);
        strtrim(curr->value, val);
    } // end-of-while
    if (fclose(file_stream)) {
        lr_error_message("Error closing file %s", configfile);
    }
    return config;    
}

char* config_get_string(struct NameValue* config, char* name, char* def) {
    char* res = def;
    while (config != NULL) {
        if (strcmp(name, config->name) == 0) {
            res = config->value;
            break;
        }
        config = config->next;        
    }
    return res;
}

// 21-4-2015 NdV vergelijkbare functie voor float/double is lastig. Door NL instellling werkt atof en sscanf niet goed.
int config_get_int(struct NameValue* config, char* name, int def) {
    int res = def;
    while (config != NULL) {
        if (strcmp(name, config->name) == 0) {
            res = atoi(config->value);
            break;
        }
        config = config->next;        
    }
    return res;
}

void config_log(struct NameValue* config) {
    while (config != NULL) {
        lr_output_message("%s -> %s", config->name, config->value);
        config = config->next;        
    }
    return;    
}

