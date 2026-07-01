/*
 * C Programming Essentials - A Complete Beginner's Guide
 *
 * This program teaches you the fundamental concepts of C programming
 * through practical examples. Each section builds on the previous one.
 *
 * Compile with: gcc -Wall -std=c99 examples/c/c-programming-essentials.c -o
 * c-programming-essentials
 * Run with: ./c-programming-essentials
 */

#include <stdio.h>  /* For input/output functions like printf() */
#include <stdlib.h> /* For memory management functions like malloc() */
#include <string.h> /* For string manipulation functions like strlen() */

/*
 * ============================================================================
 * LESSON 1: FUNCTION DECLARATIONS
 * ============================================================================
 *
 * Before we use functions, we need to "declare" them.
 * This tells the compiler "these functions exist, trust me!"
 */
void demonstrate_variables(void);
void demonstrate_arrays(void);
void demonstrate_pointers(void);
void demonstrate_memory_allocation(void);
void demonstrate_strings(void);
void demonstrate_control_flow(void);
void demonstrate_structs(void);
int add_numbers(const int a, const int b);
void print_separator(const char *title);

/*
 * ============================================================================
 * LESSON 2: THE MAIN FUNCTION - WHERE EVERYTHING STARTS
 * ============================================================================
 */
int main(void) {
  printf("=== Welcome to C Programming Essentials! ===\n\n");

  /*
   * We'll call each demonstration function in order.
   * Think of functions like chapters in a book - each teaches one concept.
   */
  demonstrate_variables();
  demonstrate_arrays();
  demonstrate_pointers();
  demonstrate_memory_allocation();
  demonstrate_strings();
  demonstrate_control_flow();
  demonstrate_structs();

  printf("\n=== Congratulations! You've learned C essentials! ===\n");
  return 0; /* Success! */
}

/*
 * ============================================================================
 * LESSON 3: VARIABLES AND DATA TYPES
 * ============================================================================
 *
 * Variables are like labeled boxes that store different types of data.
 */
void demonstrate_variables(void) {
  print_separator("VARIABLES AND DATA TYPES");

  /*
   * Integer types - for whole numbers
   * 'int' can typically hold numbers from about -2 billion to +2 billion
   */
  int age = 25;
  int temperature = -10;

  /*
   * Floating-point types - for decimal numbers
   * 'float' is smaller but less precise
   * 'double' is larger and more precise (usually preferred)
   */
  const float price = 19.99f; /* 'f' tells compiler this is a float */
  const double pi = 3.14159265359;

  /*
   * Character type - for single letters/symbols
   * Characters are stored as numbers (ASCII codes)
   */
  const char grade = 'A';

  /*
   * Boolean-like values - C doesn't have true 'bool' in older standards
   * We use int: 0 = false, anything else = true
   */
  int is_student = 1; /* 1 means true */

  /* Print all our variables */
  printf("Age: %d years old\n", age); /* %d = integer */
  printf("Temperature: %d°C\n", temperature);
  printf("Price: $%.2f\n", price); /* %.2f = 2 decimal places */
  printf("Pi: %.10f\n", pi);       /* %.10f = 10 decimal places */
  printf("Grade: %c\n", grade);    /* %c = character */
  printf("Is student: %s\n",
         is_student ? "Yes" : "No"); /* Conditional operator */

  /*
   * KEY CONCEPT: Variable Declaration
   * Format: type variable_name = initial_value;
   *
   * Common types:
   * - int: whole numbers
   * - float/double: decimal numbers
   * - char: single characters
   * - You can change values after declaration!
   */
  age = 26; /* Now age is 26 instead of 25 */
  printf("Next year I'll be: %d\n", age);

  printf("\n");
}

/*
 * ============================================================================
 * LESSON 4: ARRAYS - STORING MULTIPLE VALUES
 * ============================================================================
 *
 * Arrays are like a row of numbered boxes, all holding the same type of data.
 */
void demonstrate_arrays(void) {
  print_separator("ARRAYS");

  /*
   * Array declaration: type name[size]
   * Arrays in C are zero-indexed: first element is at position 0
   */
  int scores[5] = {95, 87, 92, 78, 89}; /* Array of 5 integers */

  /* You can also declare and fill later */
  int more_scores[3];
  more_scores[0] = 85; /* First element (position 0) */
  more_scores[1] = 90; /* Second element (position 1) */
  more_scores[2] = 88; /* Third element (position 2) */

  printf("Test scores: ");

  /*
   * Loop through array to print all values
   * for(start; condition; increment)
   */
  for (int i = 0; i < 5; i++) {
    printf("%d ", scores[i]);
  }
  printf("\n");

  /* Show the manually filled array too */
  printf("More test scores: ");
  for (int i = 0; i < 3; i++) {
    printf("%d ", more_scores[i]);
  }
  printf("\n");

  /* Calculate average */
  int sum = 0;
  for (int i = 0; i < 5; i++) {
    sum += scores[i]; /* Same as: sum = sum + scores[i] */
  }
  double average = (double)sum / 5; /* Cast to double for decimal result */
  printf("Average score: %.1f\n", average);

  /*
   * Character arrays can store text
   * In C, strings are just arrays of characters ending with '\0'
   */
  char message[20] = "Hello Arrays!";
  printf("Message: %s\n", message); /* %s = string */

  /*
   * IMPORTANT: Array bounds!
   * C doesn't check if you go outside array limits - this causes crashes!
   */
  /* scores[10] = 100;  // DANGER! scores only has 5 elements (0-4) */

  printf("\n");
}

/*
 * ============================================================================
 * LESSON 5: POINTERS - THE HEART OF C
 * ============================================================================
 *
 * Pointers are variables that store memory addresses.
 * Think of them like house addresses - they tell you WHERE data lives.
 */
void demonstrate_pointers(void) {
  print_separator("POINTERS");

  /*
   * Regular variable - stores a value
   */
  int number = 42;

  /*
   * Pointer variable - stores the ADDRESS of another variable
   * int* means "pointer to an integer"
   * &number means "address of number"
   */
  int *pointer_to_number = &number;

  printf("Value of number: %d\n", number);
  printf("Address of number: %p\n", (void *)&number); /* %p = pointer/address */
  printf("Value stored in pointer: %p\n", (void *)pointer_to_number);
  printf("Value pointed to by pointer: %d\n",
         *pointer_to_number); /* * = dereference */

  /*
   * Key pointer operators:
   * & = "address of" operator
   * * = "dereference" operator (get the value at that address)
   */

  /* Change value through pointer */
  *pointer_to_number = 100; /* This changes 'number' to 100! */
  printf("After changing through pointer, number = %d\n", number);

  /*
   * Pointer arithmetic - you can do math with pointers!
   */
  int numbers[3] = {10, 20, 30};
  int *ptr = numbers; /* Points to first element */

  printf("Array via pointer arithmetic:\n");
  for (int i = 0; i < 3; i++) {
    printf("  Element %d: %d (at address %p)\n", i, *(ptr + i),
           (void *)(ptr + i));
  }

  /*
   * Why pointers matter:
   * 1. Efficient - pass addresses instead of copying large data
   * 2. Dynamic memory - allocate memory as needed
   * 3. Data structures - linked lists, trees, etc.
   * 4. Function parameters - modify variables from other functions
   */

  printf("\n");
}

/*
 * ============================================================================
 * LESSON 6: DYNAMIC MEMORY ALLOCATION
 * ============================================================================
 *
 * So far, all our variables have "automatic" storage - they're created when
 * declared and destroyed when the function ends. Sometimes we need memory
 * that persists longer, or we don't know how much we need until runtime.
 */
void demonstrate_memory_allocation(void) {
  print_separator("DYNAMIC MEMORY ALLOCATION");

  printf("How many numbers do you want to store? ");
  int count;
  scanf("%d", &count); /* Read user input */

  /*
   * malloc() = "memory allocate"
   * Asks the operating system for a block of memory
   * Returns a pointer to that memory, or NULL if it fails
   */
  int *dynamic_array = malloc(count * sizeof(int));

  /*
   * ALWAYS check if malloc succeeded!
   * If the system is out of memory, malloc returns NULL
   */
  if (dynamic_array == NULL) {
    printf("Error: Could not allocate memory!\n");
    return; /* Exit this function early */
  }

  /* Fill the array with some values */
  printf("Filling array with squares:\n");
  for (int i = 0; i < count; i++) {
    dynamic_array[i] = (i + 1) * (i + 1); /* Store square numbers */
    printf("  Position %d: %d\n", i, dynamic_array[i]);
  }

  /*
   * CRUCIAL: Every malloc() must have a matching free()!
   * free() returns the memory to the operating system
   * Forgetting this causes "memory leaks" - your program uses more
   * and more memory until the system runs out.
   */
  free(dynamic_array);
  dynamic_array = NULL; /* Good practice: set pointer to NULL after freeing */

  /*
   * Other memory functions:
   * - calloc(): like malloc() but initializes memory to zero
   * - realloc(): change the size of previously allocated memory
   */

  printf("Memory allocation demo complete!\n\n");
}

/*
 * ============================================================================
 * LESSON 7: STRINGS - TEXT MANIPULATION
 * ============================================================================
 *
 * In C, strings are arrays of characters ending with '\0' (null terminator).
 * This is different from many other languages that have built-in string types.
 */
void demonstrate_strings(void) {
  print_separator("STRINGS");

  /*
   * Different ways to create strings
   */
  char greeting1[] = "Hello";   /* Array size calculated automatically */
  char greeting2[20] = "World"; /* Fixed size array */
  char *greeting3 = "from C!";  /* Pointer to string literal */

  printf("Greeting parts: '%s', '%s', '%s'\n", greeting1, greeting2, greeting3);

  /*
   * String length - remember, strings end with '\0'
   */
  printf("Length of '%s': %zu characters\n", greeting1, strlen(greeting1));

  /*
   * String concatenation (joining strings)
   * strcat() modifies the first string by adding the second to it
   */
  char full_greeting[50] = "Hello "; /* Make sure it's big enough! */
  strcat(full_greeting, "World ");
  strcat(full_greeting, greeting3);
  printf("Full greeting: '%s'\n", full_greeting);

  /*
   * String copying
   */
  char copy[50];
  strcpy(copy, full_greeting); /* Copy full_greeting into copy */
  printf("Copy: '%s'\n", copy);

  /*
   * String comparison
   * In C, you can't use == to compare strings!
   * Use strcmp() instead
   */
  if (strcmp(greeting1, "Hello") == 0) {
    printf("The greeting is 'Hello'!\n");
  }

  /*
   * Dynamic string allocation
   */
  char *user_name = malloc(100 * sizeof(char));
  if (user_name != NULL) {
    printf("Enter your name: ");
    fgets(user_name, 100, stdin); /* Safer than scanf for strings */

    /* Remove newline that fgets includes */
    user_name[strcspn(user_name, "\n")] = '\0';

    printf("Hello, %s! Nice to meet you.\n", user_name);
    free(user_name); /* Remember to free! */
  }

  printf("\n");
}

/*
 * ============================================================================
 * LESSON 8: CONTROL FLOW - MAKING DECISIONS AND LOOPS
 * ============================================================================
 */
void demonstrate_control_flow(void) {
  print_separator("CONTROL FLOW");

  /*
   * if/else statements - make decisions
   */
  int score = 85;
  printf("Your score: %d\n", score);

  if (score >= 90) {
    printf("Grade: A (Excellent!)\n");
  } else if (score >= 80) {
    printf("Grade: B (Good job!)\n");
  } else if (score >= 70) {
    printf("Grade: C (Passing)\n");
  } else {
    printf("Grade: F (Need to study more)\n");
  }

  /*
   * while loop - repeat while condition is true
   */
  printf("\nCountdown: ");
  int countdown = 5;
  while (countdown > 0) {
    printf("%d ", countdown);
    countdown--; /* Same as: countdown = countdown - 1 */
  }
  printf("Blast off!\n");

  /*
   * for loop - repeat a specific number of times
   */
  printf("Even numbers 1-10: ");
  for (int i = 2; i <= 10; i += 2) { /* i += 2 means i = i + 2 */
    printf("%d ", i);
  }
  printf("\n");

  /*
   * Demonstrate our custom function
   */
  int result = add_numbers(15, 25);
  printf("Using our function: 15 + 25 = %d\n", result);

  /*
   * switch statement - choose one of many options
   */
  char operation = '+';
  int a = 10, b = 5;
  printf("\nCalculating %d %c %d = ", a, operation, b);

  switch (operation) {
  case '+':
    printf("%d\n", a + b);
    break; /* Remember break! */
  case '-':
    printf("%d\n", a - b);
    break;
  case '*':
    printf("%d\n", a * b);
    break;
  case '/':
    if (b != 0) {
      printf("%.2f\n", (double)a / b);
    } else {
      printf("Error: Division by zero!\n");
    }
    break;
  default:
    printf("Unknown operation!\n");
  }

  printf("\n");
}

/*
 * ============================================================================
 * LESSON 9: STRUCTURES - CUSTOM DATA TYPES
 * ============================================================================
 *
 * Structures let you group related data together.
 * Think of them like a form with multiple fields.
 */

/* Define a structure BEFORE main() */
struct Student {
  char name[50];
  int age;
  float gpa;
  char major[30];
};

void demonstrate_structs(void) {
  print_separator("STRUCTURES");

  /*
   * Create and initialize a structure
   */
  struct Student student1 = {"Alice Johnson", 20, 3.75, "Computer Science"};

  /* Access structure members with the dot operator */
  printf("Student Information:\n");
  printf("  Name: %s\n", student1.name);
  printf("  Age: %d\n", student1.age);
  printf("  GPA: %.2f\n", student1.gpa);
  printf("  Major: %s\n", student1.major);

  /* You can modify structure members */
  student1.age = 21;   /* Birthday! */
  student1.gpa = 3.80; /* Improved grades */

  printf("\nAfter updates:\n");
  printf("  Age: %d\n", student1.age);
  printf("  GPA: %.2f\n", student1.gpa);

  /*
   * Structures with pointers
   */
  struct Student *student_ptr = &student1;

  /* Access through pointer with -> operator */
  printf("\nAccessing through pointer:\n");
  printf("  Name: %s\n", student_ptr->name); /* -> is shorthand for (*ptr). */
  printf("  Major: %s\n", student_ptr->major);

  /*
   * Array of structures - declare closer to where it's used
   */
  printf("\nClass roster:\n");
  struct Student class[3] = {{"Bob Smith", 19, 3.2, "Mathematics"},
                             {"Carol Davis", 21, 3.9, "Physics"},
                             {"David Wilson", 20, 3.6, "Chemistry"}};

  for (int i = 0; i < 3; i++) {
    printf("  %d. %s (GPA: %.2f)\n", i + 1, class[i].name, class[i].gpa);
  }

  printf("\n");
}

/*
 * ============================================================================
 * HELPER FUNCTIONS
 * ============================================================================
 */

/*
 * Function that adds two numbers and returns the result
 * Shows how to pass parameters and return values
 */
int add_numbers(const int a, const int b) {
  const int result = a + b;
  return result; /* Send result back to caller */
}

/*
 * Function to print section separators
 * 'const' means we promise not to modify the string
 * 'void' means this function doesn't return anything
 */
void print_separator(const char *title) { printf("=== %s ===\n", title); }

/*
 * ============================================================================
 * CONGRATULATIONS!
 * ============================================================================
 *
 * You've now learned the essential building blocks of C programming:
 *
 * 1. Variables & Data Types - storing different kinds of information
 * 2. Arrays - storing multiple values of the same type
 * 3. Pointers - working with memory addresses (C's superpower!)
 * 4. Dynamic Memory - allocating memory as needed
 * 5. Strings - handling text data
 * 6. Control Flow - making decisions and repeating actions
 * 7. Structures - grouping related data together
 * 8. Functions - organizing code into reusable pieces
 *
 * Next steps to continue learning:
 * - File I/O (reading/writing files)
 * - Advanced pointers (function pointers, pointer to pointers)
 * - Linked lists and other data structures
 * - Preprocessor directives (#define, #include)
 * - Multi-file programs and header files
 * - Error handling and debugging techniques
 *
 * Remember the golden rules of C:
 * 1. Always check malloc() return values
 * 2. Every malloc() needs a matching free()
 * 3. Be careful with array bounds
 * 4. Initialize your variables
 * 5. Use meaningful variable names
 *
 * Keep practicing, and you'll become a C expert! 🚀
 */
