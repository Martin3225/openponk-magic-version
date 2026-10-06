# OpenPonk dev – rozšíření

Oddělená kopie OpenPonku v5.1.0 (macOS ARM) se třemi rozšířeními.

| Rozšíření | Co dělá |
|---|---|
| Hover v dropdownech | Položka pod myší je v rozbalovacích seznamech zvýrazněná (barva `mouseOverColor` z tématu). |
| Duplikace (Cmd+D / Ctrl+D) | Duplikuje vybrané elementy diagramu. Je i v kontextovém menu jako „Duplicate“. |
| Generalizační množiny | Popisek ukazuje obě vlastnosti, např. `{incomplete, overlapping}`, a u nepojmenované množiny už nepíše „set“. |
| Multiplicita | Ve formuláři vlastností i v MCP jde psát `x..y` i `x...y`, reálná čísla a desetinnou čárku (`0,5..2,5`). Neplatný zápis se odmítne s hláškou a nic nezmění. |
| Tidy (uklizení) | Menu Layout > „Tidy (remove overlaps)“ a MCP `auto_layout`: rozestoupí překrývající se třídy a přesune popisky hran na volná místa, rozmístění zachová. |
| MCP server | `http://127.0.0.1:47100/mcp`: Claude (nebo jiný MCP klient) může číst a upravovat otevřené diagramy. |

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

- Funguje se všemi notacemi, protože typy elementů se berou z palety diagramu. U OntoUML to znamená stereotypové položky (Kind, SubKind, Role, Relator, Phase…) i vztahy (Mediation, Material, ComponentOf, MemberOf…), které se vytvoří i se stereotypem. Stereotyp existujícího elementu jde změnit přes `set_properties` s `"stereotype": "SubKind"`. Specifické funkce OntoUML (validace, transformace, vzory) přes MCP dostupné nejsou.
- Export PNG z OpenPonku po změně velikosti plátna občas vykreslí jen výřez: Roassal obnoví kreslicí plochu morphu až během kreslení, tím změní velikost plátna a OpenPonk mezitím posune kameru. MCP proto před exportem nastaví morphu cílovou velikost a plochu obnoví předem.
- Prázdný UML balíček bez profilů si OpenPonk přiřadí k pluginu „OntoUML UFO-A“ (první vyhovující plugin). Projekt založený jako „UML Class Editor“ se proto v `list_projects` hlásí jako OntoUML. Stejně se chová i GUI.
- Každá změna je pojmenovaný krok v undo OpenPonku („MCP: …“), takže jde vrátit i přes Cmd+Z.
- Nástroje běží v UI procesu OpenPonku. Případná chyba se vrátí klientovi jako chybový výsledek a v aplikaci neotevře debugger.
- Bezpečnost: server poslouchá jen na 127.0.0.1 a odmítá požadavky s hlavičkou Origin z jiné než lokální stránky (ochrana proti DNS rebinding). Jakýkoli lokální proces ale může diagramy číst, měnit a ukládat do souborů. Nástroj pro spuštění libovolného kódu v image server záměrně nemá.

## Vývoj

```
src/                     Tonel balíčky (zdroj pravdy)
  OpenPonk-Extras        hover, duplikace
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
