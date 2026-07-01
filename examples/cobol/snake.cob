      * PORTABLE LINE-MODE SNAKE IN ANSI COBOL-85.
      * NO SCREEN SECTION, CALLS, INTRINSICS, OR VENDOR EXTENSIONS.
       IDENTIFICATION DIVISION.
       PROGRAM-ID. SNAKE.

       ENVIRONMENT DIVISION.

       DATA DIVISION.
       WORKING-STORAGE SECTION.
       77  PLAY-ROWS              PIC 99 VALUE 10.
       77  PLAY-COLS              PIC 99 VALUE 20.
       77  BOARD-ROWS             PIC 99 VALUE 12.
       77  BOARD-COLS             PIC 99 VALUE 22.
       77  MAX-CELLS              PIC 999 VALUE 200.

       77  ROW-IDX                PIC 99 VALUE 0.
       77  COL-IDX                PIC 99 VALUE 0.
       77  PART-IDX               PIC 999 VALUE 0.
       77  PREV-IDX               PIC 999 VALUE 0.
       77  LAST-PART              PIC 999 VALUE 0.
       77  COMMAND-IDX            PIC 99 VALUE 0.
       77  COMMAND-SIZE           PIC 99 VALUE 20.

       77  NEW-ROW                PIC S99 VALUE 0.
       77  NEW-COL                PIC S99 VALUE 0.
       77  BOARD-ROW-IDX          PIC 99 VALUE 0.
       77  BOARD-COL-IDX          PIC 99 VALUE 0.

       77  SNAKE-LEN              PIC 999 VALUE 0.
       77  SCORE                  PIC 999 VALUE 0.
       77  MOVE-COUNT             PIC 9(5) VALUE 0.
       77  FOOD-ROW               PIC 99 VALUE 0.
       77  FOOD-COL               PIC 99 VALUE 0.
       77  RANDOM-SEED            PIC 999 VALUE 137.
       77  RANDOM-WORK            PIC 9(5) VALUE 0.
       77  RANDOM-QUOTIENT        PIC 999 VALUE 0.

       77  CURRENT-DIR            PIC X VALUE "R".
       77  MOVE-KEY               PIC X VALUE SPACE.
       77  DELTA-ROW              PIC S9 VALUE 0.
       77  DELTA-COL              PIC S9 VALUE 1.

       77  GAME-OVER              PIC X VALUE "N".
       77  PLAYER-QUIT            PIC X VALUE "N".
       77  PLAYER-WON             PIC X VALUE "N".
       77  ATE-FOOD               PIC X VALUE "N".
       77  FOOD-OK                PIC X VALUE "N".
       77  COLLISION-FOUND        PIC X VALUE "N".
       77  BUFFER-END             PIC X VALUE "N".
       77  VALID-MOVE             PIC X VALUE "N".
       77  END-REASON             PIC X(12) VALUE SPACES.

       01  COMMAND-BUFFER.
           05  COMMAND-CHAR OCCURS 20 TIMES PIC X.

       01  BOARD.
           05  BOARD-ROW OCCURS 12 TIMES.
               10  BOARD-CELL OCCURS 22 TIMES PIC X.

       01  SNAKE-BODY.
           05  SNAKE-PART OCCURS 200 TIMES.
               10  SNAKE-ROW PIC 99.
               10  SNAKE-COL PIC 99.

       PROCEDURE DIVISION.
       MAIN-PROCEDURE.
           PERFORM START-GAME
           PERFORM DRAW-BOARD
           PERFORM UNTIL GAME-OVER = "Y"
               PERFORM READ-COMMANDS
               PERFORM PROCESS-COMMANDS
           END-PERFORM
           PERFORM DRAW-BOARD
           IF PLAYER-WON = "Y"
               DISPLAY "YOU FILLED THE BOARD. FINAL SCORE: " SCORE
           ELSE
               IF PLAYER-QUIT = "Y"
                   DISPLAY "YOU QUIT. FINAL SCORE: " SCORE
               ELSE
                   DISPLAY "GAME OVER: " END-REASON
                   DISPLAY "FINAL SCORE: " SCORE
               END-IF
           END-IF
           STOP RUN.

       START-GAME.
           MOVE 3 TO SNAKE-LEN
           MOVE 0 TO SCORE
           MOVE 0 TO MOVE-COUNT
           MOVE "R" TO CURRENT-DIR
           MOVE 0 TO DELTA-ROW
           MOVE 1 TO DELTA-COL
           MOVE "N" TO GAME-OVER
           MOVE "N" TO PLAYER-QUIT
           MOVE "N" TO PLAYER-WON
           MOVE SPACES TO END-REASON
           MOVE 5 TO SNAKE-ROW (1)
           MOVE 10 TO SNAKE-COL (1)
           MOVE 5 TO SNAKE-ROW (2)
           MOVE 9 TO SNAKE-COL (2)
           MOVE 5 TO SNAKE-ROW (3)
           MOVE 8 TO SNAKE-COL (3)
           PERFORM PLACE-FOOD.

       DRAW-BOARD.
           PERFORM CLEAR-BOARD
           PERFORM DRAW-FOOD
           PERFORM DRAW-SNAKE
           DISPLAY " "
           DISPLAY " "
           DISPLAY "SCORE: " SCORE "  LENGTH: " SNAKE-LEN
           DISPLAY "MOVES: " MOVE-COUNT "  DIRECTION: " CURRENT-DIR
           PERFORM VARYING ROW-IDX FROM 1 BY 1
               UNTIL ROW-IDX > BOARD-ROWS
               DISPLAY BOARD-ROW (ROW-IDX)
           END-PERFORM
           DISPLAY "TYPE MOVES LIKE DDSSAW THEN ENTER."
           DISPLAY "BLANK ENTER CONTINUES ONCE. Q QUITS.".

       CLEAR-BOARD.
           PERFORM VARYING ROW-IDX FROM 1 BY 1
               UNTIL ROW-IDX > BOARD-ROWS
               PERFORM VARYING COL-IDX FROM 1 BY 1
                   UNTIL COL-IDX > BOARD-COLS
                   IF ROW-IDX = 1 OR ROW-IDX = BOARD-ROWS
                       MOVE "#" TO BOARD-CELL (ROW-IDX, COL-IDX)
                   ELSE
                       IF COL-IDX = 1 OR COL-IDX = BOARD-COLS
                           MOVE "#" TO BOARD-CELL (ROW-IDX, COL-IDX)
                       ELSE
                           MOVE SPACE TO BOARD-CELL (ROW-IDX, COL-IDX)
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM.

       DRAW-FOOD.
           ADD 1 TO FOOD-ROW GIVING BOARD-ROW-IDX
           ADD 1 TO FOOD-COL GIVING BOARD-COL-IDX
           MOVE "*" TO BOARD-CELL (BOARD-ROW-IDX, BOARD-COL-IDX).

       DRAW-SNAKE.
           PERFORM VARYING PART-IDX FROM SNAKE-LEN BY -1
               UNTIL PART-IDX < 1
               ADD 1 TO SNAKE-ROW (PART-IDX) GIVING BOARD-ROW-IDX
               ADD 1 TO SNAKE-COL (PART-IDX) GIVING BOARD-COL-IDX
               IF PART-IDX = 1
                   MOVE "O" TO BOARD-CELL
                       (BOARD-ROW-IDX, BOARD-COL-IDX)
               ELSE
                   MOVE "o" TO BOARD-CELL
                       (BOARD-ROW-IDX, BOARD-COL-IDX)
               END-IF
           END-PERFORM.

       READ-COMMANDS.
           MOVE SPACES TO COMMAND-BUFFER
           DISPLAY "MOVES? " WITH NO ADVANCING
           ACCEPT COMMAND-BUFFER.

       PROCESS-COMMANDS.
           MOVE "N" TO BUFFER-END
           MOVE 1 TO COMMAND-IDX
           IF COMMAND-CHAR (1) = SPACE
               MOVE SPACE TO MOVE-KEY
               PERFORM APPLY-COMMAND
           ELSE
               PERFORM UNTIL COMMAND-IDX > COMMAND-SIZE
                   OR BUFFER-END = "Y" OR GAME-OVER = "Y"
                   MOVE COMMAND-CHAR (COMMAND-IDX) TO MOVE-KEY
                   IF MOVE-KEY = SPACE
                       MOVE "Y" TO BUFFER-END
                   ELSE
                       PERFORM APPLY-COMMAND
                   END-IF
                   ADD 1 TO COMMAND-IDX
               END-PERFORM
           END-IF.

       APPLY-COMMAND.
           MOVE "N" TO VALID-MOVE
           IF MOVE-KEY = "Q" OR MOVE-KEY = "q"
               MOVE "Y" TO GAME-OVER
               MOVE "Y" TO PLAYER-QUIT
               MOVE "QUIT" TO END-REASON
               MOVE "Y" TO BUFFER-END
           ELSE
               IF MOVE-KEY = SPACE
                   MOVE "Y" TO VALID-MOVE
               END-IF
               IF MOVE-KEY = "W" OR MOVE-KEY = "w"
                   MOVE "Y" TO VALID-MOVE
               END-IF
               IF MOVE-KEY = "S" OR MOVE-KEY = "s"
                   MOVE "Y" TO VALID-MOVE
               END-IF
               IF MOVE-KEY = "A" OR MOVE-KEY = "a"
                   MOVE "Y" TO VALID-MOVE
               END-IF
               IF MOVE-KEY = "D" OR MOVE-KEY = "d"
                   MOVE "Y" TO VALID-MOVE
               END-IF
               IF VALID-MOVE = "Y"
                   IF MOVE-KEY NOT = SPACE
                       PERFORM CHANGE-DIRECTION
                   END-IF
                   PERFORM MOVE-SNAKE
                   ADD 1 TO MOVE-COUNT
                   PERFORM DRAW-BOARD
               END-IF
           END-IF.

       CHANGE-DIRECTION.
           IF MOVE-KEY = "W" OR MOVE-KEY = "w"
               IF CURRENT-DIR NOT = "D"
                   MOVE "U" TO CURRENT-DIR
               END-IF
           END-IF
           IF MOVE-KEY = "S" OR MOVE-KEY = "s"
               IF CURRENT-DIR NOT = "U"
                   MOVE "D" TO CURRENT-DIR
               END-IF
           END-IF
           IF MOVE-KEY = "A" OR MOVE-KEY = "a"
               IF CURRENT-DIR NOT = "R"
                   MOVE "L" TO CURRENT-DIR
               END-IF
           END-IF
           IF MOVE-KEY = "D" OR MOVE-KEY = "d"
               IF CURRENT-DIR NOT = "L"
                   MOVE "R" TO CURRENT-DIR
               END-IF
           END-IF
           IF CURRENT-DIR = "U"
               MOVE -1 TO DELTA-ROW
               MOVE 0 TO DELTA-COL
           END-IF
           IF CURRENT-DIR = "D"
               MOVE 1 TO DELTA-ROW
               MOVE 0 TO DELTA-COL
           END-IF
           IF CURRENT-DIR = "L"
               MOVE 0 TO DELTA-ROW
               MOVE -1 TO DELTA-COL
           END-IF
           IF CURRENT-DIR = "R"
               MOVE 0 TO DELTA-ROW
               MOVE 1 TO DELTA-COL
           END-IF.

       MOVE-SNAKE.
           ADD DELTA-ROW TO SNAKE-ROW (1) GIVING NEW-ROW
           ADD DELTA-COL TO SNAKE-COL (1) GIVING NEW-COL
           PERFORM CHECK-WALL
           IF GAME-OVER NOT = "Y"
               PERFORM CHECK-FOOD
               PERFORM CHECK-BODY
           END-IF
           IF GAME-OVER NOT = "Y"
               PERFORM SHIFT-SNAKE
               MOVE NEW-ROW TO SNAKE-ROW (1)
               MOVE NEW-COL TO SNAKE-COL (1)
               IF ATE-FOOD = "Y"
                   ADD 1 TO SCORE
                   IF SNAKE-LEN = MAX-CELLS
                       MOVE "Y" TO GAME-OVER
                       MOVE "Y" TO PLAYER-WON
                       MOVE "FILLED BOARD" TO END-REASON
                   ELSE
                       PERFORM PLACE-FOOD
                   END-IF
               END-IF
           END-IF.

       CHECK-WALL.
           IF NEW-ROW < 1 OR NEW-ROW > PLAY-ROWS
               MOVE "Y" TO GAME-OVER
               MOVE "HIT WALL" TO END-REASON
           END-IF
           IF NEW-COL < 1 OR NEW-COL > PLAY-COLS
               MOVE "Y" TO GAME-OVER
               MOVE "HIT WALL" TO END-REASON
           END-IF.

       CHECK-FOOD.
           MOVE "N" TO ATE-FOOD
           IF NEW-ROW = FOOD-ROW AND NEW-COL = FOOD-COL
               MOVE "Y" TO ATE-FOOD
               ADD 1 TO SNAKE-LEN
           END-IF.

       CHECK-BODY.
           MOVE "N" TO COLLISION-FOUND
           MOVE SNAKE-LEN TO LAST-PART
           SUBTRACT 1 FROM LAST-PART
           PERFORM VARYING PART-IDX FROM 1 BY 1
               UNTIL PART-IDX > LAST-PART
               IF NEW-ROW = SNAKE-ROW (PART-IDX)
                   IF NEW-COL = SNAKE-COL (PART-IDX)
                       MOVE "Y" TO COLLISION-FOUND
                   END-IF
               END-IF
           END-PERFORM
           IF COLLISION-FOUND = "Y"
               MOVE "Y" TO GAME-OVER
               MOVE "HIT BODY" TO END-REASON
           END-IF.

       SHIFT-SNAKE.
           PERFORM VARYING PART-IDX FROM SNAKE-LEN BY -1
               UNTIL PART-IDX < 2
               SUBTRACT 1 FROM PART-IDX GIVING PREV-IDX
               MOVE SNAKE-ROW (PREV-IDX) TO SNAKE-ROW (PART-IDX)
               MOVE SNAKE-COL (PREV-IDX) TO SNAKE-COL (PART-IDX)
           END-PERFORM.

       PLACE-FOOD.
           MOVE "N" TO FOOD-OK
           PERFORM UNTIL FOOD-OK = "Y"
               PERFORM NEXT-RANDOM
               MOVE RANDOM-SEED TO RANDOM-WORK
               DIVIDE PLAY-ROWS INTO RANDOM-WORK
                   GIVING RANDOM-QUOTIENT REMAINDER FOOD-ROW
               ADD 1 TO FOOD-ROW
               PERFORM NEXT-RANDOM
               MOVE RANDOM-SEED TO RANDOM-WORK
               DIVIDE PLAY-COLS INTO RANDOM-WORK
                   GIVING RANDOM-QUOTIENT REMAINDER FOOD-COL
               ADD 1 TO FOOD-COL
               MOVE "Y" TO FOOD-OK
               PERFORM VARYING PART-IDX FROM 1 BY 1
                   UNTIL PART-IDX > SNAKE-LEN
                   IF FOOD-ROW = SNAKE-ROW (PART-IDX)
                       IF FOOD-COL = SNAKE-COL (PART-IDX)
                           MOVE "N" TO FOOD-OK
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM.

       NEXT-RANDOM.
           COMPUTE RANDOM-WORK = RANDOM-SEED * 73 + 41
           DIVIDE 997 INTO RANDOM-WORK
               GIVING RANDOM-QUOTIENT REMAINDER RANDOM-SEED.
