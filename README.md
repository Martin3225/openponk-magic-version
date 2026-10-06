# OpenPonk dev – rozšíření

Oddělená kopie OpenPonku v5.1.0 (macOS ARM) s rozšířeními.

| Rozšíření | Co dělá |
|---|---|
| Hover v dropdownech | Položka pod myší je v rozbalovacích seznamech zvýrazněná (barva `mouseOverColor` z tématu). |
| Duplikace (Cmd+D / Ctrl+D) | Duplikuje vybrané elementy diagramu. Je i v kontextovém menu jako „Duplicate“. |
| Generalizační množiny | Popisek ukazuje obě vlastnosti, např. `{incomplete, overlapping}`, a u nepojmenované množiny už nepíše „set“. |
| Multiplicita | Ve formuláři vlastností i v MCP jde psát `x..y` i `x...y`, reálná čísla a desetinnou čárku (`0,5..2,5`). Neplatný zápis se odmítne s hláškou a nic nezmění. |
| Tidy (uklizení) | Menu Layout > „Tidy (remove overlaps)“ a MCP `auto_layout`: rozestoupí překrývající se třídy a přesune popisky hran na volná místa, rozmístění zachová. |
| OntoUML asistent | Živá kontrola modelu se srozumitelným vysvětlením a rychlými opravami, stereotyp jedním písmenem (K, S, R, P, E…) nebo z menu (T), generalizační množiny (⌘G), přidávání z textu (⌘E). Viz níže. |
| MCP server | `http://127.0.0.1:47100/mcp`: Claude (nebo jiný MCP klient) může číst a upravovat otevřené diagramy, kontrolovat OntoUML modely a přidávat prvky z textu. |

## Spuštění

```bash
./build/openponk-plugins
```

MCP server se spustí automaticky se startem image (jen v této kopii). Port se dá změnit proměnnou prostředí `OPENPONK_MCP_PORT`.

## Duplikace

- Kopie vzniká standardní cestou jako element z palety, takže je zaregistrovaná, vykreslená a ukládá se do `.opp`.
- Kopíruje se model (název, příznaky, u UML viditelnost, typy, multiplicity, komentáře, parametry operací a stereotypy včetně tagovaných hodnot), velikost a barvy tvaru. Kopie se posune o 20 px.
- Obsah elementu jde s ním: atributy a operace třídy, stavy a aktivity účastníka v BORM, datové toky na komunikaci.
- Hrany se kopírují, když se kopírují oba jejich konce (i když nebyly vybrané). Entita v ERD tak zůstane napojená na zkopírované atributy. U UML asociací se kopírují i konce: role, multiplicita, agregace a navigabilita.
- Celá duplikace je jeden krok v undo („Duplicate“). Kopie se stanou novým výběrem, takže opakované Cmd+D pokračuje dál.
- Odkazy na jiné elementy (např. typ atributu) míří na originál, nekopírují se.

Známá omezení:

- Kopíruje se to, co je vidět v diagramu. Atribut skrytý přes Hide se nezkopíruje.
- Profily (definice stereotypů): OpenPonk nezobrazí konec `base_…` nové extension, dokud se projekt znovu nenačte. Stejně se chová i kreslení extension z palety.
- Zkratka funguje, když má fokus plátno (jako ostatní zkratky OpenPonku). Někdy je potřeba do plátna nejdřív kliknout.

## Tidy

- Zachová rozmístění a řeší jen překryvy, celé jako jeden undo krok „Tidy“.
- Třídy, které se překrývají nebo jsou blíž než 30 px, odsune od sebe.
- Třídu, přes kterou vede cizí hrana, odsune stranou.
- Každý popisek hrany (jméno asociace, multiplicita, role, generalizační množina) zkusí na několika místech podél hrany a z obou stran a vybere místo s nejmenším překryvem s třídami, ostatními popisky a hranami. Popisky ukotvené ke konci hrany (multiplicity) mění jen stranu a odstup od čáry, aby undo vrátilo přesně původní stav.
- Kontejnery (balíčky s třídami uvnitř) zůstávají na místě a hranice (Boundary) se ignorují.
- Vestavěné layoutery OpenPonku (Hierarchical, Tree, Dominance Tree, Grid) rozmístí uzly znovu od začátku. Na větším modelu dopadly špatně: Hierarchical ho roztáhl do šířky 3800 px a Dominance Tree ho rozházel.

## OntoUML asistent

Psaný pro cvičení, kde studenti s OntoUML začínají: co nejméně hledání v menu a u každé chyby vysvětlení, co je špatně a jak to opravit. Texty asistenta jsou česky nebo anglicky (Settings > OpenPonk > OntoUML assistant language, výchozí čeština). Položky, které přidává do menu OpenPonku, jsou anglicky jako zbytek OpenPonku, aby se v jednom menu nemíchaly jazyky. Termíny OntoUML zůstávají anglicky vždy.

### Živá kontrola modelu

- Pod plátnem OntoUML diagramu je stavový řádek, např. `OntoUML: 3 chyby`. Aktualizuje se chvíli po každé změně (po každém kroku, který jde vrátit přes undo), takže student hned vidí, co jeho úprava způsobila.
- Prvky s chybou mají na pravém horním rohu červený odznak (s počtem, je-li chyb víc). Při každém zoomu má stejnou velikost a při tažení třídy jde s ní. Po najetí myší se ukáže, co je špatně, kliknutím se otevře seznam s tou chybou.
- „Zobrazit seznam“ otevře panel: vlevo problémy, vpravo vysvětlení a tlačítka.
  - **Rychlá oprava**, kde to jde. Fáze bez množiny dostanou množinu `{disjoint, complete}`, existující množina fází se nastaví na `{disjoint, complete}` a u třídy bez stereotypu se otevře menu stereotypů.
  - **Ukázat v diagramu**: vybere prvek a posune plátno.
  - **Odkaz do dokumentace OntoUML.**
- Pravidla jsou verifikace a detekce antipatternů z OpenPonku (OpenPonk-OntoUML-Verifications). Asistent je pouští po jednotlivých prvcích, takže napůl nakreslený vztah nikdy neotevře debugger. Jejich anglické technické hlášky překládá do vysvětlení se jmény prvků a s výčtem povolených stereotypů.
- Duplicity se slučují (obě pravidla o závislosti role, povolené podtypy a nadtypy). Chyba zděděná podtypy se hlásí jen jednou, u příčiny: „Role «Member» není definovaná vztahem … Tím se vyřeší i: Borrower, Reviewer.“
- Vlastní kontroly navíc: třída bez stereotypu (chyba, verifikace OpenPonku ji jinak tiše přeskočí), vztah bez stereotypu, více tříd stejného jména a třída bez názvu (varování).
- Varování (antipatterny a doporučení) se ukazují jen po zaškrtnutí „Ukázat i varování“. Bývají v pořádku a trvale zobrazená by zahlcovala chyby.
- Odznaky kreslí průhledná vrstva nad plátnem, nejsou to tvary diagramu. Nejdou vybrat, neukládají se a do exportu (PNG, SVG, PDF i MCP) se nedostanou, takže ani do odevzdaného obrázku. Panel se přidává jen do diagramů OntoUML. Ostatní notace i obyčejné UML diagramy (OpenPonk je otevírá pluginem OntoUML) vypadají jako dřív.
- Kontrola trvá na modelu s 36 třídami asi 10 ms, proto běží přímo v UI procesu.

Původní příkazy Model > Verification (Verify model, Detect anti-patterns) zůstaly beze změny. Výsledky ukazují v Inspectoru a obarvují obrysy prvků, a tyto barvy se ukládají do `.opp`. Studentům je lepší je nedoporučovat.

### Stereotyp: písmena na plátně, T pro menu

S vybranými třídami (a fokusem na plátně) nastaví stereotyp jediné písmeno. Platí pro celý výběr a jde vrátit jedním undo:

| Klávesa | Stereotyp | Klávesa | Stereotyp |
|---|---|---|---|
| K | Kind | C | Category |
| S | SubKind | Shift+C | Collective |
| R | Role | Q | Quality |
| Shift+R | RoleMixin | Shift+Q | Quantity |
| P | Phase | O | Mode (mOde) |
| Shift+P | PhaseMixin | I | Mixin (mIxin) |
| E | Relator (rElator) | | |

- Pravidlo: první písmeno názvu, a když je obsazené, druhé. Shift dává variantu. M je vynechané, protože OpenPonk po puštění M přepíná maximalizaci okna.
- **T** (také ⌘T, Ctrl+T a v kontextovém menu „Change stereotype...“) otevře u myši menu stereotypů. Stereotypy jsou seskupené tak, jak se učí: sortály, nesortály a aspekty. Každý má barvu z notace OntoUML, krátké vysvětlení s příkladem a vpravo svoje písmeno, takže menu slouží i jako tahák.
- U vztahů nabízí menu stereotypy vztahů. Psaní v menu filtruje položky, šipky a Enter vybírají. Aktuální stereotyp je označený a nechybí „bez stereotypu“.
- ⌘T a Ctrl+T se na Macu nemusí do OpenPonku vůbec dostat: v image fungují (ověřeno i přes obsluhu událostí SDL), ale při ručním zkoušení klávesa do OpenPonku nedorazila. Samotné T funguje vždy.

### Generalizační množina (⌘G / Ctrl+G, „Generalization set...“)

- Stačí vybrat podtřídy (šipky generalizací jsou malé a špatně se trefují). Funguje i předek spolu s několika podtřídami, samotný předek (vezmou se všechny jeho podtřídy) nebo šipky generalizací.
- Čtyři druhy množin menu vysvětluje tím, co znamenají pro instance předka: `{disjoint, complete}` = každá instance «Osoba» patří právě do jedné z nich. U fází je `{disjoint, complete}` označená jako doporučená.
- Jsou-li generalizace už v množině, množina se změní (případně rozšíří), nepřidá se druhá. „Odebrat z množiny“ ji zruší.

### Přidat z textu (⌘E / Ctrl+E, kontextové menu plátna i menu Model > „Add from text...“)

Okno, kde se prvky píší po řádcích:

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

- Při psaní ukazuje, co se přidá, a chyby podle řádků s návrhem opravy: „Řádek 2: neznámý stereotyp «Kid», myslel jsi «Kind»?“ nebo „neznámá třída «Univrzita», myslel jsi «Univerzita»?“. Dokud je v textu chyba, nepřidá nic.
- Vpravo je tahák zápisu. „Vložit vzor“ vloží jako text vzory OntoUML: fáze, roli definovanou relátorem, RoleMixin, vlastnosti (Quality, Mode) a celek s částmi či kolektiv se členy. Text se pak jen přepíše na vlastní jména. Vzory OpenPonku (Model > Patterns) naproti tomu zakládají samostatný diagram s obecnými jmény.
- Třídy, které už v diagramu jsou, se použijí podle jména (na velikosti písmen nezáleží). U existující třídy jde i změnit stereotyp. Existující generalizace se nezdvojí.
- Přidá se vše jako jeden krok undo. Nové třídy se rozmístí do řad podle generalizací (předek nahoře), pod svého předka, pokud už v diagramu je, a relátory dolů mezi třídy, které spojují. Pak proběhne Tidy a nové prvky zůstanou vybrané.
- Směr vztahů odpovídá pravidlům OpenPonku: vlevo relátor, celek nebo nositel vlastnosti (`Auto 1 --characterization-- 1 Barva`, `Tým 0..1 --memberOf-- 1..* Hráč`). Derivation (vztah relátoru ke vztahu) se textem zapsat nedá.
- Cmd+Enter nebo Ctrl+Enter přidá, okno zůstane otevřené pro další text.

## MCP server

Claude Code: v této složce je `.mcp.json`, Claude Code se při startu zeptá na schválení serveru `openponk`. Globálně ho jde přidat takto:

```bash
claude mcp add --transport http openponk http://127.0.0.1:47100/mcp
```

Nástroje:

| Nástroj | Popis |
|---|---|
| `list_projects`, `list_notations` | Otevřené projekty s diagramy a dostupné notace |
| `create_project`, `open_project`, `save_project` | Nový projekt (prázdná šablona notace), otevření a uložení `.opp` |
| `get_diagram` | Elementy diagramu: id, typ, název, pozice, vnoření, konce hran, vlastnosti |
| `list_element_types` | Typy z palety diagramu (uzly a hrany) |
| `create_element`, `connect_elements` | Vytvoření uzlu a hrany podle názvu položky palety |
| `set_properties`, `move_element` | Změna vlastností (včetně UML `type`, `multiplicity` a `stereotype`), přesun a změna velikosti (x, y = levý horní roh) |
| `set_association_end` | Konec UML/OntoUML asociace u daného elementu: role, multiplicita, agregace, navigabilita |
| `create_generalization_set` | Generalizační množina z generalizací se stejným rodičem: disjoint/overlapping, complete/incomplete (DC, OC, OI…) |
| `auto_layout` | `tidy` (výchozí) nebo vestavěné layoutery OpenPonku (`default`, `hierarchical`, `tree`, `dominance`, `grid`) |
| `delete_elements`, `duplicate_elements` | Smazání (včetně závislých elementů) a duplikace |
| `undo`, `redo` | Krok zpět a vpřed |
| `export_diagram_png` | Diagram jako obrázek |
| `verify_model` | Kontrola OntoUML modelu jako v editoru: id a jméno prvku, vysvětlení, odkaz do dokumentace, rychlá oprava; `language` `en` nebo `cs`, `include_warnings` |
| `create_from_text` | Přidání prvků zápisem z okna Přidat z textu (s `dry_run` jen plán a problémy) |
| `list_patterns`, `apply_pattern` | Vzory OntoUML jako text a jejich přidání do diagramu |

- Funguje se všemi notacemi, protože typy elementů se berou z palety diagramu. U OntoUML to znamená stereotypové položky (Kind, SubKind, Role, Relator, Phase…) i vztahy (Mediation, Material, ComponentOf, MemberOf…), které se vytvoří i se stereotypem. Stereotyp existujícího elementu jde změnit přes `set_properties` s `"stereotype": "SubKind"`. Kontrolu modelu a přidávání z textu zpřístupňují `verify_model`, `create_from_text` a vzory (`list_patterns`, `apply_pattern`). Jazyk jejich textů si volí klient pro každé volání zvlášť, jazyk GUI se tím nemění. Transformace OntoUML přes MCP dostupné nejsou.
- Export PNG z OpenPonku po změně velikosti plátna občas vykreslí jen výřez: Roassal obnoví kreslicí plochu morphu až během kreslení, tím změní velikost plátna a OpenPonk mezitím posune kameru. MCP proto před exportem nastaví morphu cílovou velikost a plochu obnoví předem.
- Prázdný UML balíček bez profilů si OpenPonk přiřadí k pluginu „OntoUML UFO-A“ (první vyhovující plugin). Projekt založený jako „UML Class Editor“ se proto v `list_projects` hlásí jako OntoUML. Stejně se chová i GUI.
- Každá změna je pojmenovaný krok v undo OpenPonku („MCP: …“), takže jde vrátit i přes Cmd+Z.
- Nástroje běží v UI procesu OpenPonku. Případná chyba se vrátí klientovi jako chybový výsledek a v aplikaci neotevře debugger.
- Bezpečnost: server poslouchá jen na 127.0.0.1 a odmítá požadavky s hlavičkou Origin z jiné než lokální stránky (ochrana proti DNS rebinding). Jakýkoli lokální proces ale může diagramy číst, měnit a ukládat do souborů. Nástroj pro spuštění libovolného kódu v image server záměrně nemá.

## Vývoj

```
src/                     Tonel balíčky (zdroj pravdy)
  OpenPonk-Extras        hover, duplikace, Tidy, multiplicity, OPDiagramBuilder (sdílené vytváření prvků)
  OpenPonk-Extras-OntoUML  OntoUML asistent: kontrola, panel, menu, přidávání z textu
  OpenPonk-MCP           MCP server a nástroje
  *-Tests                testy
tools/build.sh           obnoví čistý image z build/pristine, nahraje src/ a uloží
tools/test.sh [balíčky]  spustí testy (výchozí OpenPonk-Extras-Tests)
tools/regress.sh         všechny testy OpenPonku nad kopií image
tools/peval.sh           headless eval Smalltalku nad vývojovým image
build/pristine/          čistý image v5.1.0
```

`tools/build.sh` vyžaduje, aby vývojový OpenPonk neběžel, protože přepisuje jeho image. Testovací skripty spouštějí headless instanci s MCP serverem na portu 47998, aby neobsadila port 47100 běžícího GUI. `tools/mcp_smoke.py` projde MCP relaci proti běžícímu OpenPonku.

Úpravy mimo vlastní balíčky (při přechodu na novou verzi OpenPonku je zkontroluj):

- `SpDropListMorph>>listMorphClass` (Spec) je přepsaná, aby vracela `OPHoverIconListMorph`, podtřídu původní `PluggableIconListMorph`.
- `EditableDropListMorph>>listMorphClass` je nová metoda (dědí ji `OPEditableDropListMorph`).
- `OPUmlGeneralizationLabel>>defaultTextForSet:on:`, `showIncomplete` a `showOverlapping` (OpenPonk-ClassEditor) jsou přepsané kvůli popiskům množin. Testy OpenPonku `OPUmlGeneralizationSetsOfControllerEditorTest>>testAddNewSetAndUndoRemovesLabelFromDiagram` a `>>testAddNewSetToStandaloneGeneralizationAndUndoClearsLabel` očekávají původní text `set {}`, takže s rozšířením selhávají.
- `OPUmlClassPropertyViewModel>>writeMultiplicityFrom:to:` a `OPUmlAssociationViewModel>>writeMultiplicityFrom:to:` (OpenPonk-ClassEditor) jsou přepsané a používají `OPMultiplicityParser`.
- `OPEditorLayout>>applyOn:` (OpenPonk-Spec) je přepsaná: vloží panel kontroly OntoUML mezi plátno a lištu se zoomem, jen u editorů pluginu OntoUML.
