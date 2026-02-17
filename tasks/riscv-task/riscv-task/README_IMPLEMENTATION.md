# RISC-V Prozessor Implementierung - Dokumentation

Diese Datei dokumentiert die Implementierung des vereinfachten RISC-V Prozessors und enthält Anweisungen zum Ausführen der Simulation.

## Implementierungsdetails

Die folgenden Module wurden vervollständigt, um den Prozessor funktionsfähig zu machen:

### 1. ALU (Arithmetic Logic Unit) - `ALU.sv`
Die ALU führt mathematische und logische Operationen aus und berechnet das Zero-Flag für Verzweigungen.

*   **Zero Flag**: Das `zero` Signal wird auf `1` gesetzt, wenn das Ergebnis (`result`) `0` ist. Dies wird für den `beq` Befehl benötigt.
    ```verilog
    assign zero = (result == 0);
    ```
*   **Operationen**: Ein `case`-Statement wählt die Operation basierend auf dem `ALU_ctrl` Signal:
    *   `AND`: 
    *   `OR`
    *   `ADD`
    *   `SUB`

### 2. Datenspeicher (Data Memory) - `data_memory.sv`
Der Datenspeicher kombiniert ROM (Read-Only, unterer Adressbereich) und RAM (Read-Write, oberer Adressbereich).

*   **Lesen (Read)**:
    *   Es wird geprüft, ob `ctrl_mem_r` aktiv ist.
    *   Adressen < `DATA_MEMORY_ROM_DEPTH` lesen aus dem `rom_memory`.
    *   Adressen >= `DATA_MEMORY_ROM_DEPTH` lesen aus dem `ram_memory` (unter Abzug des Offsets).
    *   Wenn inaktiv, wird `0` ausgegeben.
*   **Schreiben (Write)**:
    *   Nur möglich, wenn `ctrl_mem_w` aktiv ist UND die Adresse im RAM-Bereich liegt.
*   **Reset**:
    *   Bei aktivem `rst` Signal werden alle Einträge im `ram_memory` mit einer Schleife auf `0` gesetzt.

### 3. Registerdatei (Register File) - `register_file.sv`
Verwaltet die 32 General-Purpose Register des Prozessors.

*   **Reset**: Setzt alle Register (`RF[0]` bis `RF[31]`) auf `0`.
*   **Schreiben**:
    *   Schreibt `w_data` in das Register `RF[reg_num_w]`, wenn das Steuersignal `ctrl_reg_w` aktiv ist.

### 4. Steuereinheit (Control Unit) - `control_unit.sv`
Die State-Machine, die Befehle dekodiert und Steuersignale setzt.

*   **LOAD (`ld`)**: ALU berechnet Adresse (Offset), Speicher liest, Ergebnis wird ins Register geschrieben.
*   **STORE (`sd`)**: ALU berechnet Adresse, Registerwert wird in den Speicher geschrieben.
*   **ARITH (`add`, `sub`, `and`, `or`)**: ALU führt Operation aus, Ergebnis ins Register.
*   **BRANCH (`beq`)**: ALU subtrahiert Werte (Opcode `SUB`), `ctrl_branch` aktiviert (PC springt, wenn Zero-Flag gesetzt).

#### Erklärung der Steuersignale

*   **`ctrl_ALU_op`** (2 Bit): Bestimmt die ALU-Operation (z.B. `00`=Add für L/S, `01`=Sub für Branch, `10`=R-Type).
*   **`ctrl_ALU_src`**: Wählt den zweiten ALU-Operanden (`0` = Register, `1` = Immediate).
*   **`ctrl_reg_w`**: Aktiviert das Schreiben in das Register-File.
*   **`ctrl_mem_w`**: Aktiviert das Schreiben in den Datenspeicher (Store).
*   **`ctrl_mem_r`**: Aktiviert das Lesen aus dem Datenspeicher (Load).
*   **`ctrl_mem_to_reg`**: Wählt die Quelle für das Zielregister (`0` = ALU-Ergebnis, `1` = Speicherdaten).
*   **`ctrl_branch`**: Zeigt an, ob ein Branch-Befehl vorliegt.

---

## Projekt ausführen


### Simulation starten


    ```powershell
    iverilog -g2012 -o riscv_sim common_pkg.sv ALU.sv ALU_control.sv control_unit.sv data_memory.sv imm_generator.sv instruction_memory.sv program_counter.sv register_file.sv clock_divider.sv top.sv top_tb.sv
    ```

1.  Führe die Simulation aus:

    ```powershell
    vvp riscv_sim
    ```



## Visualisierung mit GTKWave

Um die Signalverläufe grafisch darzustellen, kann **GTKWave** verwenden. Die Simulation erzeugt automatisch eine `dump.vcd` Datei.

1.  **GTKWave starten**:
    ```powershell
    gtkwave dump.vcd
    ```

2.  **Signale anzeigen**:

    *   **Basis-Signale**:
        *   `clk`: Taktsignal.
        *   `rst`: Reset-Signal.
        *   `instruction_address`: Der Programm-Counter (PC),

    *   **Datenfluss**:
        *   `instruction`: Der aktuelle Befehl (Hex-Code).
        *   `ALU_data_out`: Ergebnis der ALU (Rechenergebnis oder Speicheradresse).
        *   `debug`: Ausgabe des Test-Registers (hier erscheinen die Fibonacci-Zahlen).

    *   **Speicher & Register**:
        *   `reg_read_data_0` / `reg_read_data_1`: Werte, die aus den Registern gelesen werden.
        *   `mem_read_data`: Daten, die aus dem Speicher gelesen werden (bei `ld`).

---

## Lernenen


### 1. Wie wird der bedingte Sprung (`beq`) technisch umgesetzt?
**Frage:** Erklären Sie, wie die Hardware entscheidet, ob bei einem `beq` (Branch if Equal) Sprungbefehl tatsächlich gesprungen wird.
**Antwort:**
Die ALU führt eine Subtraktion (`SUB`) der beiden Vergleichsregister durch. Wenn die Werte gleich sind, ist das Ergebnis der Subtraktion `0`. Daraufhin setzt die ALU das `zero`-Flag auf `1`.
Die Steuereinheit aktiviert bei diesem Befehl das Signal `ctrl_branch`. Der Program Counter (PC) prüft die Logik `if (ALU_zero_flag && ctrl_branch)`. Wenn beides zutrifft (Zero-Flag ist 1 UND es handelt sich um einen Sprungbefehl), wird der Sprung-Offset auf die aktuelle Adresse addiert. Andernfalls zählt der PC normal weiter (+1).

### 2. Wie wird im Datenspeicher zwischen ROM und RAM unterschieden?
**Frage:** Wie stellt das `data_memory` Modul sicher, dass man nicht versehentlich in den ROM-Bereich schreibt?
**Antwort:**
Der Speicher ist in zwei Adressbereiche unterteilt. Adressen, die kleiner sind als `DATA_MEMORY_ROM_DEPTH` (z.B. 0-255), gehören zum ROM.
Beim Schreiben wird in der `always`-Logik explizit geprüft:
`if (ctrl_mem_w && (address >= DATA_MEMORY_ROM_DEPTH))`
Nur wenn das Schreibsignal aktiv ist UND die Adresse im RAM-Bereich (oberhalb des ROMs) liegt, wird der Schreibvorgang ausgeführt.

### 3. Welche Rolle spielt das Signal `ctrl_mem_to_reg`?
**Frage:** Wofür wird das Steuersignal `ctrl_mem_to_reg` benötigt und bei welchen Befehlen ist es aktiv?
**Antwort:**
Dieses Signal steuert einen Multiplexer vor dem Schreibeingang des Register Files. Es entscheidet, woher die Daten kommen, die in ein Register geschrieben werden sollen:
*   **0 (ALU):** Das Ergebnis der ALU-Berechnung wird gespeichert (bei `add`, `sub`, `and`, `or`, `sd`, `beq`).
*   **1 (Memory):** Ein aus dem Datenspeicher gelesener Wert wird gespeichert (nur bei `ld`).
Es ist also nur beim `LOAD`-Befehl auf `1` gesetzt.

### 4. Was passiert im Register File bei einem Reset?
**Frage:** Warum ist die Reset-Logik im Register File (`register_file.sv`) notwendig?
**Antwort:**
Die Reset-Logik stellt sicher, dass sich der Prozessor in einem definierten Ausgangszustand befindet. Wenn das `rst`-Signal anliegt, iteriert eine Schleife durch alle 32 Register (`for (i=0; i<32; i++)`) und setzt deren Inhalt hart auf `0`. Ohne diesen Schritt hätten die Register beim Start zufällige oder undefinierte Werte ("X"), was zu unvorhersehbarem Verhalten der Simulation führen würde.

### 5. Warum benötigt der `STORE` (`sd`) Befehl die ALU?
**Frage:** Ein `Store`-Befehl speichert doch nur Daten ab. Warum durchlaufen die Daten trotzdem die ALU bzw. warum wird die ALU angesteuert?
**Antwort:**
Beim `sd` (Store Doubleword) Befehl wird die ALU nicht genutzt, um die Daten zu verändern, sondern um die **Zieladresse im Speicher** zu berechnen.
Der Befehl besteht aus einer Basisadresse (in einem Register) und einem Offset (Immediate-Wert). Die ALU addiert diese beiden Werte (`Basis + Offset`), um die effektive Adresse zu erhalten, an die im Datenspeicher geschrieben werden soll. Deshalb ist `ctrl_ALU_src` auch auf `1` gesetzt (wählt Offset statt Register 2 als zweiten Operanden).

### 6. Wozu dient das Signal `ctrl_ALU_src`?
**Frage:** Erklären Sie die Funktion des Multiplexers vor dem zweiten ALU-Eingang, der durch `ctrl_ALU_src` gesteuert wird.
**Antwort:**
Dieses Signal wählt aus, ob der zweite Operand für die ALU aus einem Register (`reg_read_data_1`, wenn `0`) oder aus dem Immediate-Generator (`offset`, wenn `1`) stammt.
Dies ist notwendig, weil arithmetische Befehle wie `ADD` oder `SUB` mit zwei Registern arbeiten, während Speicherbefehle wie `LD` und `SD` einen Registerwert und eine Konstante (Offset) addieren müssen.

### 7. Wie wird das Zero-Flag generiert?
**Frage:** Beschreiben Sie die Logik innerhalb der ALU, die das Zero-Flag erzeugt.
**Antwort:**
Das Zero-Flag ist ein einzelnes Bit, das anzeigt, ob das Ergebnis der letzten Operation Null war. Im Verilog-Code wurde dies mit `assign zero = (result == 0);` realisiert. Wenn das 64-Bit `result` komplett aus Nullen besteht, wird `zero` High (`1`), sonst Low (`0`).

### 8. Was ist die Priorität von Reset vs. Write Enable?
**Frage:** Im Register File und im Methodenspeicher gibt es sowohl ein Reset-Signal (`rst`) als auch Schreib-Signale (`ctrl_reg_w`, `ctrl_mem_w`). Welches hat Vorrang?
**Antwort:**
Das Reset-Signal hat immer Vorrang. In der Implementierung wird dies durch eine `if (rst) ... else ...` Struktur realisiert. Solange `rst` aktiv ist, werden die Speicherinhalte gelöscht, unabhängig davon, ob gleichzeitig ein Schreibbefehl anliegt. Erst im `else`-Zweig (wenn `rst` inaktiv ist) wird geprüft, ob geschrieben werden soll.

### 9. Warum gibt es keine `ctrl_reg_r` (Read) Signale?
**Frage:** Wir haben `ctrl_mem_r` für den Speicher, aber keine Lese-Signale für das Register File. Warum?
**Antwort:**
Das Register File liest in dieser Architektur **immer** asynchron basierend auf den anliegenden Adressen (`reg_num_r0`, `reg_num_r1`). Es gibt keinen Zustand, in dem das Lesen "verboten" oder "deaktiviert" sein muss. Die Ausgänge zeigen einfach permanent den Wert der gewählten Register an. Der Speicher hingegen benötigt oft ein explizites Lesesignal (z.B. bei synchronen RAMs oder um Strom zu sparen), hier wurde es implementiert, um ungültige Lesezugriffe auf den RAM-Bereich zu verhindern (gibt 0 zurück, wenn nicht gelesen wird).

### 10. Wie beeinflusst der Clock Divider die Simulation?
**Frage:** In der `top.sv` gibt es einen `clock_divider`. Welche Auswirkung hat dieser auf die Ausführung im Vergleich zur Testbench?
**Antwort:**
Das Design ist für ein FPGA (Basys3) gedacht, das mit 200 MHz läuft. Der `clock_divider` reduziert diesen Takt auf ca. 1 Hz, damit man Änderungen an LEDs live sehen könnte.
In der Simulation (`top_tb.sv`) wird dieser Divider jedoch oft umgangen oder die Simulation läuft sehr lange, bis ein Taktzyklus des Prozessors ("schneller" Takt vs. "langsamer" Enable-Takt) vorbei ist. In unserer Testbench steuern wir `clk` direkt an, wodurch der Prozessor mit jedem Simulationsschritt weiterarbeitet, ohne Millionen von Zyklen auf den Divider warten zu müssen.

### 11. Wie liest man den Maschinencode?
**Frage:** Erklären Sie am Beispiel `02103083` aus `instruction_memory.mem`, wie ein 32-Bit Hex-Code in einen Assembler-Befehl übersetzt wird.
**Antwort:**
Der Hex-Code `02103083` wird zunächst in binär umgewandelt:
`0000 0010 0001 0000 0011 0000 1000 0011`

Die Aufteilung erfolgt nach dem RISC-V I-Type Format (für Load-Befehle):
1.  **Opcode (Bits 6-0):** `0000011` -> `LOAD` (definiert in `common_pkg.sv`).
2.  **rd (Bits 11-7):** `00001` -> Register `x1`.
3.  **funct3 (Bits 14-12):** `011` -> Breite `ld` (Load Doubleword).
4.  **rs1 (Bits 19-15):** `00000` -> Register `x0` (Basisadresse).
5.  **Immediate (Bits 31-20):** `000000100001` -> Dezimal `33` (Offset).

Zusammengesetzt ergibt das den Befehl: **`ld x1, 33(x0)`**
(Lade den Wert von Adresse `0 + 33` in Register `x1`).


