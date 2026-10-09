# OpenPonk Extras

Rozšíření pro modelovací nástroj [OpenPonk](https://openponk.org) 5.1.0:

- **OntoUML asistent** pro výuku konceptuálního modelování. Kontroluje model už během kreslení a každou chybu vysvětlí: co je špatně, proč a jak to opravit. Stereotyp nastavíš jedním písmenem a prvky můžeš přidávat zápisem z textu.
- **Vylepšení editoru** pro všechny notace: duplikace, uklizení překryvů, lepší zadávání multiplicit.
- **MCP server**, přes který může model číst a upravovat AI asistent (Claude Code nebo jiný MCP klient).

*English: extensions for OpenPonk 5.1.0. An OntoUML assistant (live model check with explanations and quick fixes, single-key stereotypes, adding elements from text), editor improvements and an MCP server. This documentation is in Czech. The assistant's texts are available in English as well (Settings > OpenPonk > OntoUML assistant language).*

## Přehled funkcí

### OntoUML asistent

| Funkce | Jak na ni |
|---|---|
| Živá kontrola modelu | Pod plátnem je stavový řádek (`OntoUML: 3 chyby`), prvky s chybou mají červený odznak. Aktualizuje se po každé změně. |
| Vysvětlení chyb | „Zobrazit seznam“ otevře panel s vysvětlením se jmény prvků, s rychlou opravou a s odkazem do dokumentace OntoUML. |
| Stereotyp jedním písmenem | Vyber třídy a stiskni písmeno: K = Kind, S = SubKind, R = Role, P = Phase, E = Relator… |
| Nová třída z klávesnice | Totéž písmeno bez výběru zvolí nástroj palety, klikem do plátna vznikne třída. L = Class, G = Generalization, A = Association. |
| Menu stereotypů | T (nebo ⌘T / Ctrl+T): stereotypy seskupené jako ve výuce, s barvou, krátkým vysvětlením a klávesou. |
| Generalizační množina | ⌘G / Ctrl+G nad vybranými podtřídami. Každý druh množiny je vysvětlený, pro fáze je doporučená `{disjoint, complete}`. |
| Přidat z textu | ⌘E / Ctrl+E: píšeš `Student : Role -> Osoba`. Chyby se ukazují po řádcích s návrhem opravy, k dispozici jsou vzory OntoUML. |
| Jazyk | Texty asistenta česky nebo anglicky. |

### Editor (všechny notace)

| Funkce | Jak na ni |
|---|---|
| Duplikace | ⌘D / Ctrl+D nebo „Duplicate“ v kontextovém menu. Zkopíruje vybrané prvky i s obsahem a hranami mezi nimi. |
| Tidy (uklizení) | Menu Layout > „Tidy (remove overlaps)“. Rozestoupí překrývající se prvky a přesune popisky hran na volná místa, rozmístění zachová. |
| Multiplicity | Ve vlastnostech jde psát `0..*`, `2...5`, desetinná čísla i desetinnou čárku (`0,5..2,5`). Neplatný zápis se odmítne s hláškou. |
| Popisky generalizačních množin | Ukazují obě vlastnosti, např. `{incomplete, overlapping}`. |
| Rozbalovací seznamy | Položka pod myší je zvýrazněná. |
| Oprava zkratek | V OpenPonku po vrácení (undo) vytvoření vybraného prvku přestaly fungovat všechny klávesové zkratky. Rozšíření to opravuje. |

### MCP server

Volitelný server na `http://127.0.0.1:47100/mcp`. AI asistent přes něj otevírá projekty, čte a kreslí diagramy (všechny notace), kontroluje OntoUML modely, přidává prvky z textu a exportuje obrázky. Ve výchozím stavu je vypnutý, viz [MCP server](#mcp-server-1).

## Instalace

**Potřebuješ:** OpenPonk **5.1.0**, build „All plugins“ ze stránky [OpenPonk/plugins v5.1.0](https://github.com/OpenPonk/plugins/releases/tag/v5.1.0). Archivy jsou pro Windows (`openponk-plugins-win-v5.1.0.zip`), Linux (`-linux-`) a macOS (`-mac-arm-` pro Apple Silicon, `-mac-intel-`). Jiné verze OpenPonku vyzkoušené nejsou. Rozšíření upravuje několik metod OpenPonku, takže s jinou verzí nemusí fungovat.

1. Rozbal OpenPonk a spusť ho. Na macOS postupuj podle `README.txt` v archivu (aplikace není podepsaná). Na Windows je lepší rozbalit ho do krátké cesty, třeba `C:\openponk` (viz [Windows a Linux](#windows-a-linux)).
2. V horní liště otevři **Browse > Playground**.
3. Vlož následující kód a klikni na **Do it all**:

   ```smalltalk
   Metacello new
   	baseline: 'OpenPonkExtras';
   	repository: 'github://Ralfcz/openponk-magic-version:master/src';
   	load.
   ```

   Kód stáhne rozšíření z GitHubu přes HTTPS (Iceberg). Potřebuješ připojení k internetu, Git ani účet na GitHubu nejsou potřeba.
4. **Ulož image:** Pharo > Save. Bez toho rozšíření při příštím spuštění zmizí. Když OpenPonk zavíráš křížkem, zvol Save, ne Discard.
5. Diagramy otevřené před instalací zavři a otevři znovu. Panel kontroly se přidává při otevření editoru.

**Aktualizace:** Browse > Git Repositories Browser, u repozitáře rozšíření klikni na Pull a pak ulož image (Pharo > Save).

### Windows a Linux

- Vyzkoušené je to zatím jen na macOS (Apple Silicon).
- Kód rozšíření nepoužívá nic závislého na systému, žádné volání knihoven ani pevné cesty k souborům. Zkratky s ⌘ jsou na Windows a Linuxu automaticky Ctrl, stejně jako u vlastních zkratek OpenPonku. Písmena (K, R, T…) fungují všude stejně.
- Na Windows může být problém s délkou cest. Iceberg ukládá repozitář do `pharo-local\iceberg\…` ve složce s image a nejdelší cesta má od této složky asi 120 znaků. Pokud by stahování skončilo chybou, rozbal OpenPonk do kratší cesty a zkus to znovu.

## Rychlý start s OntoUML

V otevřeném OntoUML diagramu (klikni do plátna, aby mělo fokus):

1. Bez výběru stiskni **K** a klikni do plátna. Vznikne třída «Kind» a můžeš rovnou psát její jméno, třeba Osoba.
2. **R** a klik vytvoří «Role», pojmenuj ji Student. **G**, klik na Student a klik na Osoba přidá generalizaci.
3. Stavový řádek pod plátnem hned ukáže chybu: role musí být definovaná vztahem. Klikni na odznak nebo na „Zobrazit seznam“ a přečti si vysvětlení.
4. Stiskni **⌘E / Ctrl+E**, napiš následující řádky a klikni na „Přidat do diagramu“:

   ```
   Univerzita : Kind
   Studium : Relator
   Studium 1..* --mediation-- 1 Student
   Studium * --mediation-- 1 Univerzita
   ```

   Student je teď definovaný relátorem Studium a chyba zmizí.
5. Stereotyp vybrané třídy změníš písmenem (P = Phase…) nebo menu přes **T**.

## Klávesy

Platí na plátně OntoUML diagramu. Někdy je potřeba do plátna nejdřív kliknout, aby mělo fokus (platí pro všechny zkratky OpenPonku).

| Klávesa | Stereotyp | Klávesa | Stereotyp |
|---|---|---|---|
| K | Kind | C | Category |
| S | SubKind | Shift+C | Collective |
| R | Role | Q | Quality |
| Shift+R | RoleMixin | Shift+Q | Quantity |
| P | Phase | O | Mode (mOde) |
| Shift+P | PhaseMixin | I | Mixin (mIxin) |
| E | Relator (rElator) | | |

- S vybranými třídami písmeno nastaví stereotyp celému výběru najednou (jeden krok undo). Bez vybrané třídy zvolí v paletě nástroj toho stereotypu.
- Pravidlo: první písmeno názvu, a když je obsazené, druhé. Shift dává variantu. M chybí, protože OpenPonk po puštění M maximalizuje okno.

| Klávesa | Akce |
|---|---|
| L / G / A | Nástroj palety Class (cLass) / Generalization / Association. Funguje i v UML diagramu. |
| Esc | Zruší zvolený nástroj palety. |
| T, ⌘T / Ctrl+T | Menu stereotypů u myši (pro vybrané třídy, nebo pro vybrané vztahy). |
| ⌘G / Ctrl+G | Generalizační množina z vybraných podtříd. |
| ⌘E / Ctrl+E | Přidat z textu. |
| ⌘D / Ctrl+D | Duplikovat vybrané prvky (všechny notace). |

Tooltip tlačítek palety ukazuje jejich písmeno.

## OntoUML asistent podrobně

Asistent je psaný pro cvičení, kde studenti s OntoUML začínají: co nejméně hledání v menu a u každé chyby vysvětlení, co je špatně a jak to opravit. Jazyk se nastavuje v Settings > OpenPonk > OntoUML assistant language (výchozí je čeština). Položky, které asistent přidává do menu OpenPonku, jsou anglicky jako zbytek OpenPonku, aby se v jednom menu nemíchaly jazyky. Termíny OntoUML zůstávají vždy anglicky.

Asistent se zapne jen v diagramech OntoUML. Ostatní notace a obyčejné UML diagramy vypadají jako dřív.

### Živá kontrola modelu

- Stavový řádek pod plátnem (`OntoUML: 3 chyby`) se aktualizuje chvíli po každé změně, takže je hned vidět, co úprava způsobila.
- Prvek s chybou má na pravém horním rohu červený odznak, při víc chybách s jejich počtem. Po najetí myší se ukáže, co je špatně, kliknutím se otevře seznam s touto chybou. Odznaky nejsou součástí diagramu: nejdou vybrat, neukládají se a nejsou v exportovaném obrázku.
- „Zobrazit seznam“ otevře panel. Vlevo jsou problémy, vpravo vysvětlení a tlačítka:
  - **Rychlá oprava**, kde to jde. Fáze bez množiny dostanou množinu `{disjoint, complete}`, existující množina fází se na ni přepne a u třídy bez stereotypu se otevře menu stereotypů.
  - **Ukázat v diagramu** vybere prvek a posune na něj plátno.
  - **Odkaz do dokumentace OntoUML.**
- Pravidla jsou verifikace a detekce antipatternů, které má OpenPonk (Model > Verification). Asistent jejich technické hlášky převádí na vysvětlení se jmény prvků a s výčtem povolených stereotypů. Napůl nakreslený vztah nikdy neotevře debugger.
- Chyba zděděná podtřídami se hlásí jen jednou, u příčiny: „Role «Member» není definovaná vztahem … Tím se vyřeší i: Borrower, Reviewer.“
- Navíc kontroluje třídu bez stereotypu (chyba), vztah bez stereotypu, více tříd stejného jména a třídu bez názvu (varování).
- Varování (antipatterny a doporučení) se ukazují až po zaškrtnutí „Ukázat i varování“. Často jsou v pořádku a trvale zobrazená by zakrývala chyby.

### Menu stereotypů (T)

![Menu stereotypů: sortály, nesortály a aspekty s vysvětlením a klávesou](docs/stereotype-menu.png)

- Otevře se u myši pro vybrané třídy, nebo pro vybrané vztahy, když není vybraná žádná třída. Je i v kontextovém menu jako „Change stereotype...“.
- Stereotypy jsou seskupené tak, jak se učí: sortály, nesortály a aspekty. Každý má barvu z notace OntoUML, krátké vysvětlení s příkladem a vpravo svoje písmeno, takže menu slouží i jako tahák.
- Psaní v menu filtruje položky, šipky a Enter vybírají. Aktuální stereotyp je označený a nechybí „bez stereotypu“.

### Generalizační množina (⌘G / Ctrl+G)

![Menu generalizační množiny pro fáze](docs/generalization-set-menu.png)

- Stačí vybrat podtřídy, šipky generalizací jsou malé a špatně se trefují. Funguje i předek spolu s podtřídami, samotný předek (vezmou se všechny jeho podtřídy) nebo samotné šipky.
- Druhy množin menu vysvětluje tím, co znamenají pro instance předka. Například `{disjoint, complete}` znamená, že každá instance «Osoba» patří právě do jedné z podtříd.
- Když generalizace už v množině jsou, množina se změní nebo rozšíří, druhá nevznikne. „Odebrat z množiny“ ji zruší.
- Je i v kontextovém menu jako „Generalization set...“ a funguje i v UML diagramech.

### Přidat z textu (⌘E / Ctrl+E)

![Okno Přidat z textu s chybami po řádcích](docs/add-from-text.png)

Okno otevře ⌘E / Ctrl+E, kontextové menu plátna nebo menu Model > „Add from text...“. Prvky se píšou po řádcích:

```
Osoba, Univerzita : Kind
Student, Učitel : Role -> Osoba
Dítě, Dospělý : Phase -> Osoba {disjoint, complete}     # nebo {dc}, {di}, {oc}, {oi}
Studium : Relator
Studium 1..* --mediation-- 1 Student                   # multiplicita stojí u své třídy
Studium * --mediation-- 1 Univerzita
Řidič -- Auto : řídí                                    # vztah bez stereotypu, s názvem
«Kind» Auto                                             # také <<Kind>> Auto
```

- Během psaní okno ukazuje, co se přidá, a chyby po řádcích s návrhem opravy, např. „Řádek 2: neznámý stereotyp «Kid», myslel jsi «Kind»?“. Dokud je v textu chyba, nepřidá se nic.
- Vpravo je tahák zápisu. „Vložit vzor“ vloží vzory OntoUML jako text (fáze, role definovaná relátorem, RoleMixin, vlastnosti, celek s částmi), stačí je přepsat na vlastní jména.
- Třídy, které už v diagramu jsou, se použijí podle jména (na velikosti písmen nezáleží). Existující třídě jde změnit stereotyp. Existující generalizace se nezdvojí.
- Všechno se přidá jako jeden krok undo. Nové třídy se rozmístí do řad podle generalizací (předek nahoře) a relátory pod třídy, které spojují. Pak proběhne Tidy a nové prvky zůstanou vybrané.
- Směr vztahů odpovídá pravidlům OpenPonku: vlevo je relátor, celek nebo nositel vlastnosti (`Auto 1 --characterization-- 1 Barva`, `Tým 0..1 --memberOf-- 1..* Hráč`). Derivation (vztah relátoru ke vztahu) se textem zapsat nedá.
- Cmd+Enter nebo Ctrl+Enter přidá a okno zůstane otevřené pro další text.

## Editor podrobně

### Duplikace (⌘D / Ctrl+D)

- Kopie vzniká stejně jako prvek z palety, takže se normálně ukládá do `.opp`.
- Kopíruje se model (název, příznaky, u UML viditelnost, typy, multiplicity, komentáře, parametry operací a stereotypy včetně tagovaných hodnot), velikost a barvy tvaru. Kopie se posune o 20 px.
- Obsah prvku jde s ním: atributy a operace třídy, stavy a aktivity účastníka v BORM, datové toky na komunikaci.
- Hrana se kopíruje, když se kopírují oba její konce. U UML asociací se kopírují i konce: role, multiplicita, agregace a navigabilita.
- Celá duplikace je jeden krok undo. Kopie se stanou novým výběrem, takže opakované ⌘D pokračuje dál.
- Odkazy na jiné prvky (např. typ atributu) míří na originál.
- Omezení: kopíruje se to, co je vidět v diagramu, takže atribut skrytý přes Hide se nezkopíruje. U profilů OpenPonk nezobrazí konec `base_…` nové extension, dokud se projekt znovu nenačte (stejně jako při kreslení z palety).

### Tidy

- Zachová rozmístění a řeší jen překryvy, celé jako jeden krok undo.
- Třídy, které jsou skoro v jedné řadě nebo sloupci (středy do 40 px od sebe), zarovná přesně na společnou řadu nebo sloupec. Specifičtější třídu do řady její obecnější třídy nedá.
- Třídy, které se překrývají nebo jsou blíž než 30 px, odsune od sebe. Třídu, přes kterou vede cizí hrana nebo kolem které vede blíž než 15 px, odsune stranou (jen tak daleko, aby hranu minula). Obojí opakuje, dokud se nic nepřekrývá, protože s odsunutou třídou se hýbou i její hrany.
- Hrany trasuje znovu: nejdřív zruší všechny body zlomu (i ty, které jsi přidal sám, kromě smyček z třídy do sebe) a rovnou hranu, která kříží jiné hrany, ohne kolem tříd, pokud je objížďka kratší než asi 400 px na každé ušetřené křížení a nevede přes žádnou třídu. Přednost mají pravé úhly (tvar L, Z nebo U), šikmé úseky použije jen výjimečně. Původní body zlomu vrátí ⌘Z / Ctrl+Z.
- Když křížení zůstanou, zkusí třídy posunout nebo prohodit (posun o 1 px se počítá jako 1 px objížďky, odstupy mezi třídami a od hran zůstanou dodržené) a hrany pak ohne znovu. Posuny nechá jen tehdy, když skončí s méně kříženími než samotné ohýbání. Všechna křížení odstranit nejde vždy, např. když mezi dvěma spojenými třídami leží celá hierarchie jiných tříd.
- Každý popisek hrany (jméno, multiplicita, role, generalizační množina) zkusí na několika místech podél hrany a v několika vzdálenostech od ní a vybere místo s nejmenším překryvem. Vzdálenosti se počítají od výchozí vzdálenosti popisku, takže opakované Tidy popisky od hran neodsouvá čím dál dál.
- Kontejnery (balíčky s třídami uvnitř) zůstávají na místě.
- Vestavěné layoutery OpenPonku (Hierarchical, Tree, Grid…) naproti tomu rozmístí všechno znovu od začátku.

## MCP server

Server umožní AI asistentovi pracovat s otevřeným OpenPonkem: číst a upravovat diagramy, kontrolovat OntoUML modely a ukládat projekty.

**Zapnutí:** v Playgroundu spusť (Do it all) a ulož image (Pharo > Save):

```smalltalk
OPMcpServer autoStart: true; startDefault.
```

Server pak poběží při každém spuštění OpenPonku na `http://127.0.0.1:47100/mcp`. Port změníš proměnnou prostředí `OPENPONK_MCP_PORT`. Vypnutí: `OPMcpServer autoStart: false; stopDefault.`

**Připojení Claude Code:**

```bash
claude mcp add --transport http openponk http://127.0.0.1:47100/mcp
```

Ve složce tohoto repozitáře to není potřeba, je v ní `.mcp.json`. Jiné MCP klienty připoj na stejnou adresu přes HTTP transport.

| Nástroj | Popis |
|---|---|
| `list_projects`, `list_notations` | Otevřené projekty s diagramy a dostupné notace |
| `create_project`, `open_project`, `save_project` | Nový projekt (prázdná šablona notace), otevření a uložení `.opp` |
| `get_diagram` | Prvky diagramu: id, typ, název, pozice, vnoření, konce hran, vlastnosti |
| `list_element_types` | Typy z palety diagramu (uzly a hrany) |
| `create_element`, `connect_elements` | Vytvoření uzlu a hrany podle názvu položky palety |
| `set_properties`, `move_element` | Změna vlastností (včetně UML `type`, `multiplicity` a `stereotype`), přesun a změna velikosti |
| `set_association_end` | Konec asociace: role, multiplicita, agregace, navigabilita |
| `create_generalization_set` | Generalizační množina (disjoint/overlapping, complete/incomplete) |
| `auto_layout` | `tidy` (výchozí) nebo vestavěné layoutery OpenPonku |
| `delete_elements`, `duplicate_elements` | Smazání (včetně závislých prvků) a duplikace |
| `undo`, `redo` | Krok zpět a vpřed |
| `export_diagram_png` | Diagram jako obrázek |
| `verify_model` | Kontrola OntoUML modelu jako v editoru, `language` `cs` nebo `en`, volitelně i varování |
| `create_from_text` | Přidání prvků zápisem z okna Přidat z textu (s `dry_run` jen plán a chyby) |
| `list_patterns`, `apply_pattern` | Vzory OntoUML jako text a jejich přidání do diagramu |

- Funguje se všemi notacemi, typy prvků se berou z palety diagramu. U OntoUML to jsou stereotypy (Kind, Role, Relator…) i vztahy (Mediation, Material, ComponentOf…).
- Každá změna je pojmenovaný krok v undo OpenPonku („MCP: …“), takže jde vrátit i ručně přes ⌘Z / Ctrl+Z.
- Chyba nástroje se vrátí klientovi jako chybový výsledek a v OpenPonku neotevře debugger.
- **Bezpečnost:** server poslouchá jen na 127.0.0.1 a odmítá požadavky z webových stránek s jiným než lokálním původem (ochrana proti DNS rebinding). Přihlašování ale nemá: jakýkoli program na tvém počítači může diagramy číst, měnit a ukládat soubory na libovolnou cestu. Zapínej ho jen tehdy, když ho používáš. Nástroj pro spuštění libovolného kódu záměrně nemá.

## Pro vývojáře

```
src/                          Tonel balíčky
  BaselineOfOpenPonkExtras    skupiny default (bez testů) a all (s testy)
  OpenPonk-Extras             duplikace, Tidy, multiplicity, hover, OPDiagramBuilder (vytváření prvků)
  OpenPonk-Extras-OntoUML     OntoUML asistent: kontrola, panel, menu, klávesy, přidávání z textu
  OpenPonk-MCP                MCP server a nástroje
  *-Tests                     testy (SUnit)
tools/build.sh                obnoví čistý image z build/pristine, nahraje src/ a uloží
tools/test.sh [balíčky]       spustí testy (výchozí OpenPonk-Extras-Tests)
tools/regress.sh              všechny testy OpenPonku nad kopií image
tools/peval.sh                headless eval Smalltalku nad vývojovým image
docs/                         obrázky do README
```

### Vývojové prostředí (macOS)

Složka `build/` není v gitu. Vytvoříš ji z oficiálního archivu:

```bash
unzip openponk-plugins-mac-arm-v5.1.0.zip
mv openponk-plugins-mac-arm build
mkdir build/pristine
cp build/image/openponk-plugins.image build/image/openponk-plugins.changes build/pristine/
xattr -r -d com.apple.quarantine build
tools/build.sh
./build/openponk-plugins
```

- `tools/build.sh` načte skupinu `all` (včetně testů), zkontroluje, že se nahrála každá třída, a zapne automatický start MCP serveru (`OPExtrasSetup afterBuild`). Image přepisuje, proto vyžaduje, aby vývojový OpenPonk neběžel.
- Skripty volají VM na cestě `build/Pharo.app/Contents/MacOS/Pharo`, takže fungují jen na macOS. Na jiném systému stačí upravit cestu k VM, nebo načíst `src/` z Playgroundu: `Metacello new baseline: 'OpenPonkExtras'; repository: 'tonel:///cesta/k/repozitari/src'; load: 'all'`.
- Testovací skripty pouštějí headless instanci s MCP serverem na portu 47998, aby nekolidovala s běžícím GUI na 47100. `tools/mcp_smoke.py` projde MCP relaci proti běžícímu OpenPonku.
- Stav testů: všechny testy rozšíření procházejí. Z testů OpenPonku selhávají dva kvůli změněným popiskům generalizačních množin (viz níže).

### Úpravy mimo vlastní balíčky

Rozšíření přepisuje nebo doplňuje tyto metody OpenPonku a Specu. Při přechodu na novou verzi OpenPonku je zkontroluj:

- `SpDropListMorph>>listMorphClass` (Spec) vrací `OPHoverIconListMorph`, podtřídu původní `PluggableIconListMorph`.
- `EditableDropListMorph>>listMorphClass` je nová metoda (dědí ji `OPEditableDropListMorph`).
- `OPUmlGeneralizationLabel>>defaultTextForSet:on:`, `showIncomplete` a `showOverlapping` (OpenPonk-ClassEditor) kvůli popiskům množin. Testy OpenPonku `OPUmlGeneralizationSetsOfControllerEditorTest>>testAddNewSetAndUndoRemovesLabelFromDiagram` a `>>testAddNewSetToStandaloneGeneralizationAndUndoClearsLabel` očekávají původní text `set {}`, proto s rozšířením selhávají.
- `OPUmlClassPropertyViewModel>>writeMultiplicityFrom:to:` a `OPUmlAssociationViewModel>>writeMultiplicityFrom:to:` (OpenPonk-ClassEditor) používají `OPMultiplicityParser`.
- `OPRoassalShapeContext>>roassalShapes:` (OpenPonk-Spec) vynechá tvary bez controlleru. Výběr plátna jinak mohl držet tvar smazaného prvku (typicky vybraný vztah, jehož vytvoření se vrátilo přes undo) a každá klávesa na plátně pak skončila chybou.
- `OPEditorLayout>>applyOn:` (OpenPonk-Spec) vloží panel kontroly OntoUML mezi plátno a lištu se zoomem, jen u editorů pluginu OntoUML.

### Poznámky k implementaci

- Kontrola OntoUML pouští verifikace OpenPonku po jednotlivých prvcích a každou zvlášť chrání před chybou. Na modelu s 36 třídami trvá asi 10 ms, proto běží přímo v UI procesu, se zpožděním 400 ms po poslední změně (oznámení undo manageru).
- Odznaky kreslí průhledný morph nad plátnem, ne tvary Roassalu. Proto nejsou mezi tvary diagramu, neukládají se, neexportují a mají stejnou velikost při každém zoomu.
- Původní příkazy Model > Verification ukazují výsledky v Inspectoru a obarvují obrysy prvků. Tyto barvy se ukládají do `.opp`, proto je studentům lepší nedoporučovat.
- Export PNG z OpenPonku po změně velikosti plátna občas vykreslí jen výřez: Roassal obnoví kreslicí plochu až během kreslení a OpenPonk mezitím posune kameru. MCP proto před exportem nastaví morphu cílovou velikost a plochu obnoví předem.
- Prázdný UML balíček bez profilů si OpenPonk přiřadí k pluginu „OntoUML UFO-A“. Projekt založený jako „UML Class Editor“ se proto v `list_projects` hlásí jako OntoUML (stejně se chová i GUI).
