# AXI Lite Slave Projekt Dokumentation

## 1. Änderungen

Folgende Anpassungen wurden vorgenommen, um das Projekt funktionsfähig zu machen:

1.  **Modul-Interface Implementierung (`module_axi_litev.sec`):**
    -   Das leere Verilog-Gerüst wurde mit funktionaler Logik befüllt.
    -   Implementierung der AXI4-Lite State-Machine für Schreib- (Write) und Lesezugriffe (Read).
    -   Hinzufügen von 4 internen Registern (`slv_reg0` - `slv_reg3`), die über den Bus gelesen und beschrieben werden können.
    -   Implementierung der Handshake-Signale (`READY`/`VALID`).

2.  **Testbench Anpassung (`axi_lite_tbv.sec`):**
    -   Korrektur der Modul-Instanziierung (Namensanpassung von `axi_regs_top` zu `axi_lite`).
    -   Hinzufügen von `timescale`-Direktiven, um Timing-Probleme bei der Simulation zu beheben.
    -   Erweiterung der Test-Tasks (`axi_lite_write`, `axi_lite_read`) um Debug-Ausgaben (`$display`), um den Simulationsfortschritt sichtbar zu machen.
    -   Korrektur der `assert`-Logik für die automatische Überprüfung der Ergebnisse.
    -   **Aktivierung von Test 2 (Byte-Level-Writes):** Der auskommentierte Test für Register 1 (`0x04`) wurde aktiviert. Die Adresse wurde dabei von `0x1000_0004` auf `0x0000_0004` korrigiert, um den internen Adressraum des Slaves zu treffen.

3.  **Fehlerbehebung:**
    -   Behebung eines "stuck-at-zero" Time-Problems durch korrektes Timing und Reset-Handling.

## 2. Ausführung 

### Kompilieren und Simulation starten
Zuerst kompilieren wir den Code:
```powershell
iverilog -g2012 -o simulation.vvp axi_lite_tbv.sec module_axi_litev.sec
```

Danach führen wir die Simulation aus:
```powershell
vvp simulation.vvp
```

**Erklärung:**
-   `iverilog`: Der Compiler.
-   `-g2012`: Aktiviert SystemVerilog-Support (notwendig für `logic` Datentypen).
-   `-o simulation.vvp`: Ausgabedatei .
-   `... .sec`: Die Eingabedateien.
-   `vvp`: Runtime-Engine.
-   
mit **GTKWave** betrachtet :

```powershell
gtkwave dump.vcd
```

## 3. PWM Erweiterung (LED Dimmer)

Zusätzlich zur Standard-AXI-Funktionalität wurde eine **Pulsweitenmodulation (PWM)** implementiert, um zu demonstrieren, wie Hardware über Bus-Register gesteuert wird (z.B. zum Dimmen einer LED).

### Implementierung
In `module_axi_litev.sec` wurde ein Zähler und eine Vergleichslogik hinzugefügt, die über die internen Register kontrolliert wird:
-   **Register 0 (0x00):** Setzt die **Periode** (Frequenz).
-   **Register 1 (0x04):** Setzt den **Duty Cycle** (Tastverhältnis/Helligkeit).
-   **Output:** Ein neuer Port `pwm_out`, der HIGH ist, solange der interne Zähler kleiner als der Wert in Register 1 ist.

### PWM Simulation ausführen
Es wurde eine eigene Testbench `axi_lite_pwm_tb.sec` erstellt, die drei Szenarien testet (50%, 20%, 80% Duty Cycle).

```powershell
iverilog -g2012 -o pwm_sim.vvp axi_lite_pwm_tb.sec module_axi_litev.sec
```

```powershell
vvp pwm_sim.vvp
```

```powershell
gtkwave pwm_dump.vcd
```

## 4. Verilog Befehlsreferenz

Hier eine Erklärung aller relevanten Verilog/SystemVerilog-Befehle, die im Code verwendet wurden:

### Modul-Struktur & Instanziierung
-   **`module ... endmodule`**: Definiert den Block (Chip). Alles dazwischen gehört zur Schaltung.
-   **`parameter`**: Konfigurierbare Werte (wie Konstanten), die beim Einbau des Moduls überschrieben werden können.
-   **`input / output`**: Ports, die Signale rein- oder rauslassen.
-   **`dut (...)`**: Instanziierung ("Device Under Test"). Hier wird das Modul in die Testbench eingebaut und die Ports verbunden.

### Datentypen
-   **`logic`**: (SystemVerilog) Ein flexibler Datentyp, der sowohl Wire als auch Reg ersetzen kann. Nutzt 4 Zustände (0, 1, X, Z).
-   **`reg`**: Ein Datentyp, der einen Wert speichert (Gedächtnis), notwendig in `always` Blöcken.
-   **`wire`**: Eine physikalische Leitung ohne Gedächtnis. Verbindet zwei Punkte.
-   **`integer`**: Eine 32-Bit Variable, meist für Schleifen (`for`) verwendet.
-   **`localparam`**: Konstante, die *nur* innerhalb des Moduls gilt und nicht von außen geändert werden kann.

### Prozedurale Blöcke & Timing
-   **`initial begin ... end`**: Startet bei Zeit 0 und läuft genau einmal durch (für Testbench-Start).
-   **`always @(posedge clk)`**: Läuft endlos, triggert aber nur bi steigender Taktflanke (für Flip-Flops).
-   **`forever`**: Eine Endlosschleife, z.B. um den Takt zu generieren (`forever #5 clk = ~clk`).
-   **`timescale 1ns / 1ps`**: Legt fest: Zahl `1` = 1ns, Zeitauflösung = 1ps.

### Zuweisungen & Operatoren
-   **`assign`**: Verbindet Signale dauerhaft (Hardwiring). Ändert sich der rechte Wert, ändert sich sofort der linke.
-   **`<=` (Non-blocking)**: Zuweisung, die erst *am Ende* des Taktschritts wirksam wird. Standard für getaktete Logik (`always`).
-   **`=` (Blocking)**: Zuweisung, die *sofort* wirksam wird.

### Kontrollstrukturen
-   **`if ... else`**: Standard Bedingungsabfrage. Erzeugt in Hardware Multiplexer.
-   **`case ... endcase`**: Mehrfachauswahl (wie switch-case). Hier verwendet für die Adress-Dekodierung.
-   **`task ... endtask`**: Unterprogramm in der Testbench, um Code (wie den Schreibvorgang) wiederverwendbar zu kapseln.
-   **`wait(bedingung)`**: Pausiert die Ausführung, bis das Signal wahr wird.

### System-Tasks (Simulation)
-   **`$display(...)`**: Gibt Text im Terminal aus (vgl. `printf`).
-   **`$time`**: Gibt die aktuelle Simulationszeit zurück.
-   **`$finish`**: Beendet die Simulation.
-   **`$error(...)`**: Gibt eine Fehlermeldung aus (oft genutzt wenn ein Test fehlschlägt).
-   **`$dumpfile("name.vcd")`**: Setzt den Dateinamen für die Waveforms.
-   **`$dumpvars`**: Startet das Aufzeichnen der Signale.
