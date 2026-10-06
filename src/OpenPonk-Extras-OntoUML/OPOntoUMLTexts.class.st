"
All texts of the OntoUML assistant (model check, stereotype and generalization set menus, text import) in Czech and English.

The language is chosen in the settings (OpenPonk > OntoUML assistant language); Czech by default, the course this is made for is taught in Czech. OntoUML terms (Kind, Role, Mediation...) stay in English in both languages.

Texts may contain placeholders {1}, {2}... filled by #at:with:.
"
Class {
	#name : 'OPOntoUMLTexts',
	#superclass : 'Object',
	#classVars : [
		'LanguageAnnouncer',
		'Language',
		'Tables'
	],
	#category : 'OpenPonk-Extras-OntoUML-Texts',
	#package : 'OpenPonk-Extras-OntoUML',
	#tag : 'Texts'
}

{ #category : 'accessing' }
OPOntoUMLTexts class >> at: aKey [

	^ (self tableFor: self language) at: aKey ifAbsent: [
		  (self tableFor: #en) at: aKey ifAbsent: [ aKey asString ] ]
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> at: aKey with: anArray [
	"Only {1}, {2}... are placeholders; texts also contain braces of their own, e.g. {disjoint, complete}."

	| text |
	text := self at: aKey.
	anArray withIndexDo: [ :each :index |
		text := text
			        copyReplaceAll: '{' , index printString , '}'
			        with: (each ifNil: [ '' ]) asString ].
	^ text
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> count: anInteger of: aNoun [
	"E.g. '3 chyby', '5 chyb', '1 error' (aNoun is 'error' or 'warning')."

	| form |
	form := anInteger = 1
		        ifTrue: [ 1 ]
		        ifFalse: [
			        (anInteger between: 2 and: 4)
				        ifTrue: [ 2 ]
				        ifFalse: [ 5 ] ].
	^ anInteger printString , ' ' , (self at: (aNoun , '.' , form printString) asSymbol)
]

{ #category : 'tables' }
OPOntoUMLTexts class >> csCatalog [

	^ {
		  #'group.sortals' -> 'Sortály: dávají nebo nesou identitu'.
		  #'group.nonSortals' -> 'Nesortály: společné pro různé druhy'.
		  #'group.aspects' -> 'Aspekty: vztahy a vlastnosti'.
		  #'group.relations' -> 'Vztahy'.
		  #'stereotype.Kind' -> 'rigidní, dává identitu (Osoba, Auto)'.
		  #'stereotype.SubKind' -> 'rigidní podtyp (Muž, Osobní auto)'.
		  #'stereotype.Role' -> 'vzniká vztahem, potřebuje mediation (Student, Řidič)'.
		  #'stereotype.Phase' -> 'stav podle vlastnosti, množina {disjoint, complete} (Dítě, Dospělý)'.
		  #'stereotype.Collective' -> 'skupina členů (Tým, Flotila)'.
		  #'stereotype.Quantity' -> 'množství látky (Voda, Víno)'.
		  #'stereotype.Category' -> 'rigidní, společné různým druhům (Fyzický objekt)'.
		  #'stereotype.RoleMixin' -> 'role pro různé druhy (Zákazník: osoba i firma)'.
		  #'stereotype.PhaseMixin' -> 'fáze společná různým druhům'.
		  #'stereotype.Mixin' -> 'semirigidní, společné vlastnosti různých druhů'.
		  #'stereotype.Relator' -> 'zhmotněný vztah, spojuje mediacemi (Smlouva, Jízda)'.
		  #'stereotype.Mode' -> 'vlastnost se strukturou (Nemoc, Dovednost)'.
		  #'stereotype.Quality' -> 'měřitelná vlastnost (Barva, Hmotnost)'.
		  #'stereotype.Mediation' -> 'relátor a věc, kterou spojuje'.
		  #'stereotype.Material' -> 'vztah odvozený z relátoru'.
		  #'stereotype.Characterization' -> 'Mode nebo Quality a jejich nositel'.
		  #'stereotype.ComponentOf' -> 'část funkčního celku (Motor, Auto)'.
		  #'stereotype.MemberOf' -> 'člen kolektivu (Hráč, Tým)'.
		  #'stereotype.SubCollectionOf' -> 'podskupina kolektivu'.
		  #'stereotype.SubQuantityOf' -> 'část množství'.
		  #'stereotype.Containment' -> 'množství v nádobě (Víno, Sud)'.
		  #'stereotype.Derivation' -> 'material vztah a jeho relátor'.
		  #'stereotype.DomainFormal' -> 'formální srovnávací vztah (je starší než)'.
		  #'stereotype.Formal' -> 'formální srovnávací vztah (je starší než)'.
		  #'stereotype.none' -> 'bez stereotypu' }
]

{ #category : 'tables' }
OPOntoUMLTexts class >> csProblems [

	^ {
		  #'severity.error' -> 'Chyba'.
		  #'severity.warning' -> 'Varování'.
		  #unnamed -> '(bez názvu)'.
		  #alsoFixes -> 'Tím se vyřeší i: {1}.'.
		  #'noIdentity.title' -> '«{1}» nemá identitu'.
		  #'noIdentity.text' -> '{2} musí přes generalizace dědit identitu z právě jedné třídy typu Kind, Collective nebo Quantity. Napoj «{1}» generalizací pod takovou třídu, nebo změň její stereotyp (třeba na Kind).'.
		  #'multipleIdentity.title' -> '«{1}» dědí identitu z více zdrojů'.
		  #'multipleIdentity.text' -> 'Mezi předky «{1}» je víc tříd typu Kind, Collective nebo Quantity, ale věc může mít jen jeden princip identity. Pokud je předek něco společného různým druhům, modeluj ho jako Category, RoleMixin nebo PhaseMixin.'.
		  #'generalizationLoop.title' -> 'Generalizace u «{1}» tvoří kruh'.
		  #'generalizationLoop.text' -> 'Třída je přes generalizace sama sobě předkem. Jednu z generalizací v kruhu odstraň.'.
		  #'roleWithoutRelator.title' -> 'Role «{1}» není definovaná vztahem'.
		  #'roleWithoutRelator.text' -> 'Role existuje jen díky vztahu: Student díky Studiu, Řidič díky Jízdě. Přidej relátor (třeba «Studium») a spoj ho s rolí vztahem Mediation. Na obou koncích mediace musí být dolní multiplicita aspoň 1 (ne 0..*). Stačí i mediace zděděná z nadřazené role.'.
		  #'relatorWithoutMediation.title' -> 'Relátor «{1}» nic nespojuje'.
		  #'relatorWithoutMediation.text' -> 'Relátor je zhmotněný vztah (Smlouva, Manželství, Jízda). Spoj ho vztahem Mediation s věcmi, které propojuje, celkem aspoň se dvěma.'.
		  #'relatorOneSide.title' -> 'Relátor «{1}» spojuje méně než dvě věci'.
		  #'relatorOneSide.text' -> 'Součet horních multiplicit na druhých koncích mediací musí být aspoň 2, protože relátor vždy propojuje aspoň dvě entity (Manželství dva Partnery, Smlouva Zákazníka a Dodavatele). Přidej další mediaci nebo zvyš multiplicitu.'.
		  #'notCharacterized.title' -> '{2} «{1}» nic necharakterizuje'.
		  #'notCharacterized.text' -> '{2} je vlastnost něčeho. Spoj «{1}» vztahem Characterization s třídou, které patří (Barva a Auto, Nemoc a Pacient).'.
		  #'characterizationMultiplicity.title' -> 'Characterization u «{1}» potřebuje multiplicitu 1'.
		  #'characterizationMultiplicity.text' -> '{2} patří vždy právě jednomu nositeli, proto musí být na straně nositele multiplicita přesně 1.'.
		  #'phaseNotInSet.title' -> 'Fáze «{1}» není v generalizační množině'.
		  #'phaseNotInSet.text' -> 'Fáze úplně rozdělují svého předka: všechny patří do jedné generalizační množiny {disjoint, complete}, protože každá instance je v každém okamžiku právě v jedné fázi.'.
		  #'phaseSetNotDC.title' -> 'Množina s fází «{1}» není {disjoint, complete}'.
		  #'phaseSetNotDC.text' -> 'Každá instance je v každém okamžiku právě v jedné fázi, proto musí být množina fází disjoint (nejvýš jedna) i complete (aspoň jedna).'.
		  #'invalidGeneralization.title' -> '{3} «{1}» nemůže být podtypem {4} «{2}»'.
		  #'invalidGeneralization.text' -> 'Pod {4} smí být jen: {5}. Změň stereotyp jedné z tříd, nebo generalizaci otoč či odstraň.'.
		  #'invalidRelationSource.title' -> '{2} «{1}» nemůže být zdrojem vztahu {3}'.
		  #'invalidRelationSource.text' -> 'Zdrojem vztahu {3} smí být jen: {4}. Změň stereotyp vztahu nebo třídy, případně vztah otoč.'.
		  #'invalidRelationTarget.title' -> '{2} «{1}» nemůže být cílem vztahu {3}'.
		  #'invalidRelationTarget.text' -> 'Cílem vztahu {3} smí být jen: {4}. Změň stereotyp vztahu nebo třídy, případně vztah otoč.'.
		  #'binOver.title' -> 'Oba konce vztahu «{1}» může být tatáž věc'.
		  #'binOver.text' -> 'Vztah spojuje třídy, které se mohou překrývat (stejná třída nebo předek a potomek). Rozhodni, jestli může věc být ve vztahu sama se sebou, a podle toho vztah zpřesni.'.
		  #'decInt.title' -> '«{1}» má více konkrétních předků'.
		  #'decInt.text' -> 'Třída dědí z více neabstraktních tříd. Ověř, že každá instance musí být opravdu instancí všech zároveň.'.
		  #'depPhase.title' -> 'Fáze «{1}» je ve vztahu Mediation'.
		  #'depPhase.text' -> 'Fáze se určuje vnitřní vlastností, ne vztahem. Je-li třída definovaná vztahem k relátoru, jde spíš o Role.'.
		  #'freeRole.title' -> 'Role «{1}» nemá vlastní vztah'.
		  #'freeRole.text' -> 'Role dědí závislost z nadřazené role, ale sama nemá vztah, který by ji odlišil. Doplň mediaci nebo ujasni, čím se role liší.'.
		  #'gsRig.title' -> 'Množina míchá rigidní a anti-rigidní podtypy'.
		  #'gsRig.text' -> 'V jedné generalizační množině jsou rigidní (Kind, SubKind) i anti-rigidní (Role, Phase) podtypy. Obvykle patří do dvou různých množin.'.
		  #'hetColl.title' -> 'Kolektiv «{1}» má různé druhy členů'.
		  #'hetColl.text' -> 'Kolektiv mívá členy jednoho druhu. Liší-li se části, jde spíš o funkční celek (Kind a ComponentOf).'.
		  #'homoFunc.title' -> 'Celek «{1}» má jen jeden druh částí'.
		  #'homoFunc.text' -> 'Celek z mnoha stejných částí bývá spíš Collective (MemberOf) než Kind se ComponentOf.'.
		  #'impAbs.title' -> 'Vztah «{1}» možná vede na příliš obecnou třídu'.
		  #'impAbs.text' -> 'Konec vztahu vede na třídu s více podtypy a horní multiplicitou větší než 1. Zvaž, jestli nemá vést přímo na konkrétní podtyp.'.
		  #'mixIden.title' -> '«{1}» má podtypy se stejnou identitou'.
		  #'mixIden.text' -> 'Nesortál (Category, Mixin...) slouží pro třídy s různou identitou. Mají-li všechny podtypy stejný Kind, použij místo něj SubKind nebo Role.'.
		  #'mixRig.title' -> 'Podtypy mixinu «{1}» mají stejnou rigiditu'.
		  #'mixRig.text' -> 'Mixin by měl mít rigidní i anti-rigidní podtypy. Jinak použij Category (vše rigidní) nebo RoleMixin či PhaseMixin (vše anti-rigidní).'.
		  #'multDep.title' -> '«{1}» je přímo ve více mediacích'.
		  #'multDep.text' -> 'Třída je přímo spojená s více relátory. Často jde o různé role, které by měly být samostatnými třídami.'.
		  #'partOver.title' -> '«{1}» může být částí více celků najednou'.
		  #'partOver.text' -> 'Část je ve vztahu s více celky, které se mohou překrývat. Ověř, jestli může tatáž část patřit oběma.'.
		  #'relComp.title' -> 'Vztahy u «{1}» se možná omezují'.
		  #'relComp.text' -> 'Dva vztahy mezi souvisejícími třídami mohou potřebovat doplňující omezení (třeba že jde o tutéž instanci).'.
		  #'relOver.title' -> 'Relátor «{1}» spojuje třídy, které se mohou překrývat'.
		  #'relOver.text' -> 'Mediované třídy se mohou překrývat. Ověř, jestli může tatáž instance hrát obě strany vztahu zároveň.'.
		  #'relRig.title' -> 'Relátor «{1}» je přímo spojený s rigidní třídou'.
		  #'relRig.text' -> 'Mediace obvykle vede na roli (Student), ne přímo na Kind (Osoba). Vlož mezi ně roli.'.
		  #'relSpec.title' -> 'Vztah «{1}» možná specializuje jiný vztah'.
		  #'relSpec.text' -> 'Mezi předky a potomky vedou dva podobné vztahy. Zvaž, jestli jeden není zúžením nebo odvozením druhého.'.
		  #'repRel.title' -> '«{1}» může existovat ve dvou stejných instancích'.
		  #'repRel.text' -> 'Relátor může spojovat tytéž věci vícekrát (horní multiplicity větší než 1). Je-li to záměr, instance něčím odliš (třeba datem); jinak sniž multiplicitu.'.
		  #'undefFormal.title' -> 'Formální vztah «{1}» nemá z čeho vycházet'.
		  #'undefFormal.text' -> 'Formální (srovnávací) vztah se odvozuje z atributů nebo kvalit obou tříd. Doplň je, nebo použij jiný stereotyp.'.
		  #'undefPhase.title' -> 'Fáze «{1}»: chybí vlastnost, která fáze odlišuje'.
		  #'undefPhase.text' -> 'Fáze se liší hodnotou nějaké vlastnosti (Dítě a Dospělý podle věku). Doplň předkovi atribut nebo kvalitu, podle které se fáze určuje.'.
		  #'wholeOver.title' -> 'Celek «{1}» má části, které se mohou překrývat'.
		  #'wholeOver.text' -> 'Části celku se mohou překrývat. Ověř, jestli může být tatáž instance oběma částmi zároveň.'.
		  #'noStereotype.title' -> 'Třída «{1}» nemá stereotyp'.
		  #'noStereotype.text' -> 'V OntoUML má každá třída stereotyp, který říká, jaký druh věci představuje (Kind, Role, Relator...). Bez něj ji kontrola nemůže posoudit.'.
		  #'associationNoStereotype.title' -> 'Vztah «{1}» nemá stereotyp'.
		  #'associationNoStereotype.text' -> 'I vztahy mají v OntoUML stereotyp (Mediation, Material, Characterization, ComponentOf...). Podle něj se kontroluje, co smí spojovat.'.
		  #'duplicateName.title' -> 'Více tříd se jmenuje «{1}»'.
		  #'duplicateName.text' -> 'Každý pojem by měl být v modelu jen jednou. Je-li to tatáž věc, ponech jednu třídu a vztahy přepoj na ni; jinak jednu přejmenuj.'.
		  #'unnamed.title' -> 'Třída bez názvu'.
		  #'unnamed.text' -> 'Pojmenuj třídu podstatným jménem v jednotném čísle (Osoba, Smlouva).'.
		  #'generic.title' -> '«{1}»: {2}'.
		  #'fix.createDCSet' -> 'Vytvořit množinu {disjoint, complete}'.
		  #'fix.makeDC' -> 'Nastavit {disjoint, complete}'.
		  #'fix.chooseStereotype' -> 'Vybrat stereotyp...' }
]

{ #category : 'tables' }
OPOntoUMLTexts class >> enCatalog [

	^ {
		  #'group.sortals' -> 'Sortals: provide or carry identity'.
		  #'group.nonSortals' -> 'Non-sortals: shared by different kinds'.
		  #'group.aspects' -> 'Aspects: relationships and properties'.
		  #'group.relations' -> 'Relations'.
		  #'stereotype.Kind' -> 'rigid, provides identity (Person, Car)'.
		  #'stereotype.SubKind' -> 'rigid subtype (Man, Sedan)'.
		  #'stereotype.Role' -> 'played in a relationship, needs a mediation (Student, Driver)'.
		  #'stereotype.Phase' -> 'state by a property, {disjoint, complete} set (Child, Adult)'.
		  #'stereotype.Collective' -> 'group of members (Team, Fleet)'.
		  #'stereotype.Quantity' -> 'amount of matter (Water, Wine)'.
		  #'stereotype.Category' -> 'rigid, shared by different kinds (Physical object)'.
		  #'stereotype.RoleMixin' -> 'role of different kinds (Customer: person or company)'.
		  #'stereotype.PhaseMixin' -> 'phase shared by different kinds'.
		  #'stereotype.Mixin' -> 'semi-rigid, properties shared by different kinds'.
		  #'stereotype.Relator' -> 'reified relationship, connects via mediations (Contract, Ride)'.
		  #'stereotype.Mode' -> 'property with a structure (Disease, Skill)'.
		  #'stereotype.Quality' -> 'measurable property (Color, Weight)'.
		  #'stereotype.Mediation' -> 'a relator and a thing it connects'.
		  #'stereotype.Material' -> 'relation derived from a relator'.
		  #'stereotype.Characterization' -> 'a mode or quality and its bearer'.
		  #'stereotype.ComponentOf' -> 'part of a functional whole (Engine, Car)'.
		  #'stereotype.MemberOf' -> 'member of a collective (Player, Team)'.
		  #'stereotype.SubCollectionOf' -> 'sub-collection of a collective'.
		  #'stereotype.SubQuantityOf' -> 'portion of a quantity'.
		  #'stereotype.Containment' -> 'quantity in a container (Wine, Barrel)'.
		  #'stereotype.Derivation' -> 'a material relation and its relator'.
		  #'stereotype.DomainFormal' -> 'formal comparative relation (older than)'.
		  #'stereotype.Formal' -> 'formal comparative relation (older than)'.
		  #'stereotype.none' -> 'no stereotype' }
]

{ #category : 'tables' }
OPOntoUMLTexts class >> enProblems [

	^ {
		  #'severity.error' -> 'Error'.
		  #'severity.warning' -> 'Warning'.
		  #unnamed -> '(unnamed)'.
		  #alsoFixes -> 'This also fixes: {1}.'.
		  #'noIdentity.title' -> '«{1}» has no identity'.
		  #'noIdentity.text' -> 'A {2} must inherit its identity from exactly one Kind, Collective or Quantity through generalizations. Connect «{1}» below such a class with a generalization, or change its stereotype (e.g. to Kind).'.
		  #'multipleIdentity.title' -> '«{1}» inherits identity from several sources'.
		  #'multipleIdentity.text' -> 'Among the ancestors of «{1}» there is more than one Kind, Collective or Quantity, but a thing follows only one identity principle. If the ancestor stands for something shared by different kinds, model it as a Category, RoleMixin or PhaseMixin.'.
		  #'generalizationLoop.title' -> 'Generalizations of «{1}» form a cycle'.
		  #'generalizationLoop.text' -> 'The class is its own ancestor through generalizations. Remove one of the generalizations in the cycle.'.
		  #'roleWithoutRelator.title' -> 'Role «{1}» is not defined by a relationship'.
		  #'roleWithoutRelator.text' -> 'A role exists only thanks to a relationship: a Student thanks to a Study, a Driver thanks to a Ride. Add a relator (e.g. «Study») and connect it to the role with a Mediation. Both ends of the mediation need a lower multiplicity of at least 1 (not 0..*). A mediation inherited from a super-role is enough.'.
		  #'relatorWithoutMediation.title' -> 'Relator «{1}» connects nothing'.
		  #'relatorWithoutMediation.text' -> 'A relator is a reified relationship (Contract, Marriage, Ride). Connect it with Mediations to the things it relates, at least two in total.'.
		  #'relatorOneSide.title' -> 'Relator «{1}» relates fewer than two things'.
		  #'relatorOneSide.text' -> 'The upper multiplicities on the other ends of its mediations must add up to at least 2, as a relator always relates at least two entities (a Marriage two Spouses, a Contract a Customer and a Supplier). Add another mediation or raise the multiplicity.'.
		  #'notCharacterized.title' -> '{2} «{1}» characterizes nothing'.
		  #'notCharacterized.text' -> 'A {2} is a property of something. Connect «{1}» with a Characterization to the class it belongs to (Color and Car, Disease and Patient).'.
		  #'characterizationMultiplicity.title' -> 'Characterization of «{1}» needs multiplicity 1'.
		  #'characterizationMultiplicity.text' -> 'A {2} always belongs to exactly one bearer, so the multiplicity at the bearer must be exactly 1.'.
		  #'phaseNotInSet.title' -> 'Phase «{1}» is not in a generalization set'.
		  #'phaseNotInSet.text' -> 'Phases partition their parent completely: all of them belong to one {disjoint, complete} generalization set, as every instance is in exactly one phase at any time.'.
		  #'phaseSetNotDC.title' -> 'The set of phase «{1}» is not {disjoint, complete}'.
		  #'phaseSetNotDC.text' -> 'Every instance is in exactly one phase at any time, so a set of phases must be disjoint (at most one) and complete (at least one).'.
		  #'invalidGeneralization.title' -> '{3} «{1}» cannot be a subtype of {4} «{2}»'.
		  #'invalidGeneralization.text' -> 'Only these may be below a {4}: {5}. Change the stereotype of one of the classes, or reverse or remove the generalization.'.
		  #'invalidRelationSource.title' -> '{2} «{1}» cannot be the source of a {3}'.
		  #'invalidRelationSource.text' -> 'The source of a {3} may only be: {4}. Change the stereotype of the relation or the class, or reverse the relation.'.
		  #'invalidRelationTarget.title' -> '{2} «{1}» cannot be the target of a {3}'.
		  #'invalidRelationTarget.text' -> 'The target of a {3} may only be: {4}. Change the stereotype of the relation or the class, or reverse the relation.'.
		  #'binOver.title' -> 'Both ends of «{1}» can be the same thing'.
		  #'binOver.text' -> 'The relation connects classes that can overlap (the same class, or an ancestor and a descendant). Decide whether a thing can be related to itself and make the relation more precise.'.
		  #'decInt.title' -> '«{1}» has several concrete parents'.
		  #'decInt.text' -> 'The class inherits from several non-abstract classes. Check that every instance really must be an instance of all of them at once.'.
		  #'depPhase.title' -> 'Phase «{1}» is in a Mediation'.
		  #'depPhase.text' -> 'A phase is defined by an intrinsic property, not by a relationship. If the class is defined by its relation to a relator, it is rather a Role.'.
		  #'freeRole.title' -> 'Role «{1}» has no relationship of its own'.
		  #'freeRole.text' -> 'The role inherits its dependency from a super-role but has no relationship that sets it apart. Add a mediation or clarify how the role differs.'.
		  #'gsRig.title' -> 'The set mixes rigid and anti-rigid subtypes'.
		  #'gsRig.text' -> 'One generalization set has both rigid (Kind, SubKind) and anti-rigid (Role, Phase) subtypes. They usually belong to two different sets.'.
		  #'hetColl.title' -> 'Collective «{1}» has different kinds of members'.
		  #'hetColl.text' -> 'A collective usually has members of one kind. If the parts differ, it is rather a functional whole (Kind and ComponentOf).'.
		  #'homoFunc.title' -> 'Whole «{1}» has only one kind of part'.
		  #'homoFunc.text' -> 'A whole made of many equal parts is usually a Collective (MemberOf) rather than a Kind with ComponentOf.'.
		  #'impAbs.title' -> 'Relation «{1}» may lead to a too general class'.
		  #'impAbs.text' -> 'An end of the relation leads to a class with several subtypes and an upper multiplicity above 1. Consider leading it directly to a specific subtype.'.
		  #'mixIden.title' -> '«{1}» has subtypes with the same identity'.
		  #'mixIden.text' -> 'A non-sortal (Category, Mixin...) is meant for classes of different identity. If all subtypes have the same Kind, use a SubKind or Role instead.'.
		  #'mixRig.title' -> 'Subtypes of mixin «{1}» have the same rigidity'.
		  #'mixRig.text' -> 'A Mixin should have both rigid and anti-rigid subtypes. Otherwise use a Category (all rigid) or a RoleMixin or PhaseMixin (all anti-rigid).'.
		  #'multDep.title' -> '«{1}» is directly in several mediations'.
		  #'multDep.text' -> 'The class is directly connected to several relators. These are often different roles that should be classes of their own.'.
		  #'partOver.title' -> '«{1}» can be part of several wholes at once'.
		  #'partOver.text' -> 'The part is related to several wholes that can overlap. Check whether the same part can belong to both.'.
		  #'relComp.title' -> 'Relations of «{1}» may constrain each other'.
		  #'relComp.text' -> 'Two relations between related classes may need an additional constraint (e.g. that they concern the same instance).'.
		  #'relOver.title' -> 'Relator «{1}» relates classes that can overlap'.
		  #'relOver.text' -> 'The mediated classes can overlap. Check whether the same instance can be on both sides of the relationship.'.
		  #'relRig.title' -> 'Relator «{1}» is directly connected to a rigid class'.
		  #'relRig.text' -> 'A mediation usually leads to a role (Student), not directly to a Kind (Person). Put a role between them.'.
		  #'relSpec.title' -> 'Relation «{1}» may specialize another one'.
		  #'relSpec.text' -> 'Two similar relations connect ancestors and descendants. Consider whether one is a specialization or derivation of the other.'.
		  #'repRel.title' -> '«{1}» may exist in two identical instances'.
		  #'repRel.text' -> 'The relator can connect the same things more than once (upper multiplicities above 1). If intended, distinguish the instances (e.g. by a date); otherwise lower the multiplicity.'.
		  #'undefFormal.title' -> 'Formal relation «{1}» has nothing to be based on'.
		  #'undefFormal.text' -> 'A formal (comparative) relation is derived from attributes or qualities of both classes. Add them, or use another stereotype.'.
		  #'undefPhase.title' -> 'Phase «{1}»: no property tells the phases apart'.
		  #'undefPhase.text' -> 'Phases differ in the value of some property (Child and Adult by age). Add the parent an attribute or quality that determines the phase.'.
		  #'wholeOver.title' -> 'Whole «{1}» has parts that can overlap'.
		  #'wholeOver.text' -> 'The parts of the whole can overlap. Check whether the same instance can be both parts at once.'.
		  #'noStereotype.title' -> 'Class «{1}» has no stereotype'.
		  #'noStereotype.text' -> 'In OntoUML every class has a stereotype telling what kind of thing it is (Kind, Role, Relator...). Without it the check cannot judge it.'.
		  #'associationNoStereotype.title' -> 'Relation «{1}» has no stereotype'.
		  #'associationNoStereotype.text' -> 'Relations have stereotypes in OntoUML too (Mediation, Material, Characterization, ComponentOf...). They determine what a relation may connect.'.
		  #'duplicateName.title' -> 'Several classes are named «{1}»'.
		  #'duplicateName.text' -> 'Every concept should be in the model only once. If it is the same thing, keep one class and reconnect the relations to it; otherwise rename one.'.
		  #'unnamed.title' -> 'Class without a name'.
		  #'unnamed.text' -> 'Name the class with a singular noun (Person, Contract).'.
		  #'generic.title' -> '«{1}»: {2}'.
		  #'fix.createDCSet' -> 'Create {disjoint, complete} set'.
		  #'fix.makeDC' -> 'Make it {disjoint, complete}'.
		  #'fix.chooseStereotype' -> 'Choose stereotype...' }
]

{ #category : 'tables' }
OPOntoUMLTexts class >> csUI [

	^ {
		  #'menu.current' -> '(aktuální)'.
		  #'text.line' -> 'Řádek {1}: {2}'.
		  #'text.cannotParse' -> 'nerozumím řádku, příklady jsou v nápovědě vpravo'.
		  #'text.missingStereotype' -> 'u «{1}» chybí stereotyp, napiš třeba «{1} : Kind»'.
		  #'text.missingName' -> 'chybí název třídy'.
		  #'text.missingParent' -> 'za -> chybí předek'.
		  #'text.twoStereotypes' -> 'stereotyp je zapsaný dvakrát'.
		  #'text.setNeedsParent' -> 'generalizační množina potřebuje předka: Dítě, Dospělý -> Osoba {disjoint, complete}'.
		  #'text.setNeedsOneParent' -> 'generalizační množina potřebuje právě jednoho předka'.
		  #'text.badSet' -> 'nerozumím množině «{1}», napiš třeba {disjoint, complete} nebo {dc}'.
		  #'text.relationNeedsEnds' -> 'vztah potřebuje třídu na obou stranách: Studium --mediation-- Student'.
		  #'text.unknownStereotype' -> 'neznámý stereotyp «{1}»'.
		  #'text.didYouMean' -> ', myslel jsi «{1}»?'.
		  #'text.relationStereotypeForClass' -> '«{1}» je stereotyp vztahu, třída potřebuje třeba Kind, Role nebo Relator'.
		  #'text.classStereotypeForRelation' -> '«{1}» je stereotyp třídy, vztahy mají Mediation, Material, ComponentOf...'.
		  #'text.unknownClass' -> 'neznámá třída «{1}», přidej řádek «{1} : Kind» (nebo s jiným stereotypem)'.
		  #'text.unknownClassSuggestion' -> 'neznámá třída «{1}», myslel jsi «{2}»?'.
		  #'text.conflictingStereotypes' -> '«{1}» má v textu dva stereotypy: {2} a {3}'.
		  #'text.badMultiplicity' -> 'neplatná multiplicita «{1}» (příklady: 1, 0..1, 1..*, *)'.
		  #'text.selfGeneralization' -> '«{1}» nemůže být předkem sám sobě'.
		  #'text.derivationNotSupported' -> 'Derivation spojuje relátor se vztahem, to v textu zapsat nejde'.
		  #'text.undo' -> 'Přidat z textu'.
		  #'plan.newClass' -> '+ třída «{1}» ({2})'.
		  #'plan.changeStereotype' -> '~ «{1}»: stereotyp {2} → {3}'.
		  #'plan.generalization' -> '+ generalizace {1} → {2}'.
		  #'plan.existingGeneralization' -> '= generalizace {1} → {2} už v diagramu je'.
		  #'plan.set' -> '+ množina {1}: {2} → {3}'.
		  #'plan.relation' -> '+ vztah {1}: {2} – {3}{4}'.
		  #'plan.nothing' -> 'Napiš třídy a vztahy vlevo, tady uvidíš, co se přidá.'.
		  #'plan.errors' -> 'Oprav nejdřív tyto řádky:'.
		  #'command.addFromText' -> 'Přidat z textu...'.
		  #'dialog.title' -> 'Přidat do diagramu z textu'.
		  #'dialog.add' -> 'Přidat do diagramu'.
		  #'dialog.close' -> 'Zavřít'.
		  #'dialog.templates' -> 'Vložit vzor'.
		  #'dialog.preview' -> 'Co se přidá'.
		  #'dialog.help' -> 'Třídy
  Osoba : Kind
  Student, Učitel : Role -> Osoba
  «Kind» Auto             (nebo <<Kind>> Auto)

Generalizace a množiny
  Dítě, Dospělý : Phase -> Osoba {disjoint, complete}
  Dítě, Dospělý -> Osoba {dc}       (dc, di, oc, oi)

Vztahy (multiplicita stojí u třídy, ke které patří)
  Studium 1..* --mediation-- 1 Student
  Auto 1 --characterization-- 1 Barva
  Auto 1 --componentOf-- 4 Kolo
  Tým 0..1 --memberOf-- 1..* Hráč
  Řidič -- Auto : řídí      (bez stereotypu, s názvem)

Vlevo píšeš relátor, celek nebo nositel vlastnosti.
Třídy, které už v diagramu jsou, se použijí znovu.
Název s čárkou nebo dvojtečkou dej do "uvozovek".
Řádky začínající # jsou poznámky.'.
		  #'template.phases' -> 'Fáze (rozdělení podle stavu)'.
		  #'template.phases.text' -> 'Osoba : Kind
Dítě, Dospělý : Phase -> Osoba {disjoint, complete}'.
		  #'template.relator' -> 'Role definovaná relátorem'.
		  #'template.relator.text' -> 'Osoba, Univerzita : Kind
Student : Role -> Osoba
Studium : Relator
Studium 1..* --mediation-- 1 Student
Studium * --mediation-- 1 Univerzita'.
		  #'template.roleMixin' -> 'Role pro různé druhy (RoleMixin)'.
		  #'template.roleMixin.text' -> 'Osoba, Firma : Kind
Zákazník : RoleMixin
Soukromý zákazník : Role -> Osoba, Zákazník
Firemní zákazník : Role -> Firma, Zákazník
Soukromý zákazník, Firemní zákazník -> Zákazník {disjoint, complete}
Nákup : Relator
Nákup 1..* --mediation-- 1 Zákazník'.
		  #'template.properties' -> 'Vlastnosti (Quality, Mode)'.
		  #'template.properties.text' -> 'Auto, Osoba : Kind
Barva : Quality
Nemoc : Mode
Auto 1 --characterization-- 1 Barva
Osoba 1 --characterization-- * Nemoc'.
		  #'template.parts' -> 'Celek a části, kolektiv a členové'.
		  #'template.parts.text' -> 'Auto, Motor : Kind
Auto 1 --componentOf-- 1 Motor
Flotila : Collective
Flotila 0..1 --memberOf-- 1..* Auto'.
		  #'error.1' -> 'chyba'.
		  #'error.2' -> 'chyby'.
		  #'error.5' -> 'chyb'.
		  #'warning.1' -> 'varování'.
		  #'warning.2' -> 'varování'.
		  #'warning.5' -> 'varování'.
		  #'panel.checking' -> 'Kontroluji model...'.
		  #'panel.noErrors' -> 'OntoUML: bez chyb'.
		  #'panel.noProblems' -> 'OntoUML: bez chyb a varování'.
		  #'panel.summary' -> 'OntoUML: {1}'.
		  #'panel.showList' -> 'Zobrazit seznam'.
		  #'panel.hideList' -> 'Skrýt seznam'.
		  #'panel.showWarnings' -> 'Ukázat i varování'.
		  #'panel.showWarningsHelp' -> 'Varování (antipatterny a doporučení) ukazují místa, která bývají špatně, ale mohou být v pořádku. Chyby porušují pravidla OntoUML.'.
		  #'panel.showInDiagram' -> 'Ukázat v diagramu'.
		  #'panel.learnMore' -> 'Více o pravidle v dokumentaci OntoUML'.
		  #'panel.allGood' -> 'Model splňuje pravidla OntoUML, která OpenPonk umí ověřit.'.
		  #'panel.allGoodWarnings' -> ' Tipy na možné antipatterny ukáže volba Ukázat i varování.'.
		  #'panel.selectProblem' -> 'Vyber problém v seznamu, ukáže se, co je špatně a jak to opravit.'.
		  #'command.changeStereotype' -> 'Změnit stereotyp...'.
		  #'command.generalizationSet' -> 'Generalizační množina...'.
		  #'stereotypeMenu.titleOne' -> 'Stereotyp: «{1}»'.
		  #'stereotypeMenu.titleMany' -> 'Stereotyp vybraných prvků ({1})'.
		  #'stereotypeMenu.undo' -> 'Změna stereotypu'.
		  #'gs.title' -> 'Generalizační množina: {2} → {1}'.
		  #'gs.dc' -> '{disjoint, complete}'.
		  #'gs.di' -> '{disjoint, incomplete}'.
		  #'gs.oc' -> '{overlapping, complete}'.
		  #'gs.oi' -> '{overlapping, incomplete}'.
		  #'gs.dc.note' -> 'každá instance «{1}» patří právě do jedné z nich'.
		  #'gs.di.note' -> 'každá instance «{1}» patří nejvýš do jedné z nich'.
		  #'gs.oc.note' -> 'každá instance «{1}» patří aspoň do jedné z nich'.
		  #'gs.oi.note' -> 'instance «{1}» může patřit do libovolného počtu z nich'.
		  #'gs.recommendedForPhases' -> '(doporučeno pro fáze)'.
		  #'gs.remove' -> 'Odebrat z množiny'.
		  #'gs.change' -> 'Generalizační množina'.
		  #'gs.selectFirst' -> 'Vyber podtřídy se společným předkem (nebo jejich šipky generalizace) a pak znovu zvol Generalizační množina.' }
]

{ #category : 'tables' }
OPOntoUMLTexts class >> enUI [

	^ {
		  #'menu.current' -> '(current)'.
		  #'text.line' -> 'Line {1}: {2}'.
		  #'text.cannotParse' -> 'cannot read this line, see the examples on the right'.
		  #'text.missingStereotype' -> '«{1}» needs a stereotype, e.g. «{1} : Kind»'.
		  #'text.missingName' -> 'a class name is missing'.
		  #'text.missingParent' -> 'a parent is missing after ->'.
		  #'text.twoStereotypes' -> 'the stereotype is written twice'.
		  #'text.setNeedsParent' -> 'a generalization set needs a parent: Child, Adult -> Person {disjoint, complete}'.
		  #'text.setNeedsOneParent' -> 'a generalization set needs exactly one parent'.
		  #'text.badSet' -> 'cannot read the set «{1}», write e.g. {disjoint, complete} or {dc}'.
		  #'text.relationNeedsEnds' -> 'a relation needs a class on both sides: Study --mediation-- Student'.
		  #'text.unknownStereotype' -> 'unknown stereotype «{1}»'.
		  #'text.didYouMean' -> ', did you mean «{1}»?'.
		  #'text.relationStereotypeForClass' -> '«{1}» is a relation stereotype, a class needs e.g. Kind, Role or Relator'.
		  #'text.classStereotypeForRelation' -> '«{1}» is a class stereotype, relations have Mediation, Material, ComponentOf...'.
		  #'text.unknownClass' -> 'unknown class «{1}», add a line «{1} : Kind» (or another stereotype)'.
		  #'text.unknownClassSuggestion' -> 'unknown class «{1}», did you mean «{2}»?'.
		  #'text.conflictingStereotypes' -> '«{1}» has two stereotypes in the text: {2} and {3}'.
		  #'text.badMultiplicity' -> 'invalid multiplicity «{1}» (e.g. 1, 0..1, 1..*, *)'.
		  #'text.selfGeneralization' -> '«{1}» cannot be its own parent'.
		  #'text.derivationNotSupported' -> 'a Derivation connects a relator with a relation, which cannot be written as text'.
		  #'text.undo' -> 'Add from text'.
		  #'plan.newClass' -> '+ class «{1}» ({2})'.
		  #'plan.changeStereotype' -> '~ «{1}»: stereotype {2} → {3}'.
		  #'plan.generalization' -> '+ generalization {1} → {2}'.
		  #'plan.existingGeneralization' -> '= generalization {1} → {2} is already in the diagram'.
		  #'plan.set' -> '+ set {1}: {2} → {3}'.
		  #'plan.relation' -> '+ relation {1}: {2} – {3}{4}'.
		  #'plan.nothing' -> 'Write classes and relations on the left; what will be added shows up here.'.
		  #'plan.errors' -> 'First fix these lines:'.
		  #'command.addFromText' -> 'Add from text...'.
		  #'dialog.title' -> 'Add to the diagram from text'.
		  #'dialog.add' -> 'Add to diagram'.
		  #'dialog.close' -> 'Close'.
		  #'dialog.templates' -> 'Insert pattern'.
		  #'dialog.preview' -> 'What will be added'.
		  #'dialog.help' -> 'Classes
  Person : Kind
  Student, Teacher : Role -> Person
  «Kind» Car              (or <<Kind>> Car)

Generalizations and sets
  Child, Adult : Phase -> Person {disjoint, complete}
  Child, Adult -> Person {dc}       (dc, di, oc, oi)

Relations (a multiplicity stands next to its class)
  Study 1..* --mediation-- 1 Student
  Car 1 --characterization-- 1 Color
  Car 1 --componentOf-- 4 Wheel
  Team 0..1 --memberOf-- 1..* Player
  Driver -- Car : drives    (no stereotype, with a name)

The relator, the whole or the bearer goes on the left.
Classes already in the diagram are reused.
Put a name with a comma or colon in "quotes".
Lines starting with # are comments.'.
		  #'template.phases' -> 'Phases (partition by state)'.
		  #'template.phases.text' -> 'Person : Kind
Child, Adult : Phase -> Person {disjoint, complete}'.
		  #'template.relator' -> 'Role defined by a relator'.
		  #'template.relator.text' -> 'Person, University : Kind
Student : Role -> Person
Study : Relator
Study 1..* --mediation-- 1 Student
Study * --mediation-- 1 University'.
		  #'template.roleMixin' -> 'Role of different kinds (RoleMixin)'.
		  #'template.roleMixin.text' -> 'Person, Company : Kind
Customer : RoleMixin
Private customer : Role -> Person, Customer
Corporate customer : Role -> Company, Customer
Private customer, Corporate customer -> Customer {disjoint, complete}
Purchase : Relator
Purchase 1..* --mediation-- 1 Customer'.
		  #'template.properties' -> 'Properties (Quality, Mode)'.
		  #'template.properties.text' -> 'Car, Person : Kind
Color : Quality
Disease : Mode
Car 1 --characterization-- 1 Color
Person 1 --characterization-- * Disease'.
		  #'template.parts' -> 'Whole and parts, collective and members'.
		  #'template.parts.text' -> 'Car, Engine : Kind
Car 1 --componentOf-- 1 Engine
Fleet : Collective
Fleet 0..1 --memberOf-- 1..* Car'.
		  #'error.1' -> 'error'.
		  #'error.2' -> 'errors'.
		  #'error.5' -> 'errors'.
		  #'warning.1' -> 'warning'.
		  #'warning.2' -> 'warnings'.
		  #'warning.5' -> 'warnings'.
		  #'panel.checking' -> 'Checking the model...'.
		  #'panel.noErrors' -> 'OntoUML: no errors'.
		  #'panel.noProblems' -> 'OntoUML: no errors or warnings'.
		  #'panel.summary' -> 'OntoUML: {1}'.
		  #'panel.showList' -> 'Show list'.
		  #'panel.hideList' -> 'Hide list'.
		  #'panel.showWarnings' -> 'Show warnings'.
		  #'panel.showWarningsHelp' -> 'Warnings (anti-patterns and recommendations) point at places that are often wrong but may be fine. Errors break OntoUML rules.'.
		  #'panel.showInDiagram' -> 'Show in diagram'.
		  #'panel.learnMore' -> 'Learn more in the OntoUML documentation'.
		  #'panel.allGood' -> 'The model follows the OntoUML rules OpenPonk can check.'.
		  #'panel.allGoodWarnings' -> ' Turn on Show warnings for hints on possible anti-patterns.'.
		  #'panel.selectProblem' -> 'Select a problem in the list to see what is wrong and how to fix it.'.
		  #'command.changeStereotype' -> 'Change stereotype...'.
		  #'command.generalizationSet' -> 'Generalization set...'.
		  #'stereotypeMenu.titleOne' -> 'Stereotype: «{1}»'.
		  #'stereotypeMenu.titleMany' -> 'Stereotype of the selected elements ({1})'.
		  #'stereotypeMenu.undo' -> 'Change stereotype'.
		  #'gs.title' -> 'Generalization set: {2} → {1}'.
		  #'gs.dc' -> '{disjoint, complete}'.
		  #'gs.di' -> '{disjoint, incomplete}'.
		  #'gs.oc' -> '{overlapping, complete}'.
		  #'gs.oi' -> '{overlapping, incomplete}'.
		  #'gs.dc.note' -> 'every «{1}» is exactly one of them'.
		  #'gs.di.note' -> 'every «{1}» is at most one of them'.
		  #'gs.oc.note' -> 'every «{1}» is at least one of them'.
		  #'gs.oi.note' -> 'a «{1}» can be any number of them'.
		  #'gs.recommendedForPhases' -> '(recommended for phases)'.
		  #'gs.remove' -> 'Remove from the set'.
		  #'gs.change' -> 'Generalization set'.
		  #'gs.selectFirst' -> 'Select subclasses with a common parent (or their generalization arrows), then choose Generalization set again.' }
]

{ #category : 'class initialization' }
OPOntoUMLTexts class >> initialize [

	Tables := nil
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> language [
	"#cs or #en."

	^ OPOntoUMLLanguageOverride value ifNil: [ Language ifNil: [ #cs ] ]
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> during: aLanguage do: aBlock [
	"Evaluate aBlock with texts in aLanguage (#cs or #en), without changing the language of the user interface."

	^ OPOntoUMLLanguageOverride value: aLanguage asSymbol during: aBlock
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> patterns [
	"Ids of the modelling patterns written as text (template.<id> is the name, template.<id>.text the text)."

	^ #( 'phases' 'relator' 'roleMixin' 'properties' 'parts' )
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> language: aSymbol [

	Language := aSymbol asSymbol.
	self announcer announce: OPOntoUMLLanguageChanged new
]

{ #category : 'settings' }
OPOntoUMLTexts class >> languageName [

	^ self language = #en
		  ifTrue: [ 'English' ]
		  ifFalse: [ 'Čeština' ]
]

{ #category : 'settings' }
OPOntoUMLTexts class >> languageName: aString [

	self language: (aString = 'English'
			 ifTrue: [ #en ]
			 ifFalse: [ #cs ])
]

{ #category : 'accessing' }
OPOntoUMLTexts class >> announcer [

	^ LanguageAnnouncer ifNil: [ LanguageAnnouncer := Announcer new ]
]

{ #category : 'settings' }
OPOntoUMLTexts class >> settingsOn: aBuilder [

	<systemsettings>
	(aBuilder pickOne: #languageName)
		parent: #openponk;
		target: self;
		label: 'OntoUML assistant language';
		description: 'Language of the OntoUML model check, of the stereotype and generalization set menus and of adding elements from text.';
		default: 'Čeština';
		domainValues: #( 'Čeština' 'English' );
		order: 45
]

{ #category : 'tables' }
OPOntoUMLTexts class >> tableFor: aLanguage [

	^ (Tables ifNil: [ Tables := Dictionary new ]) at: aLanguage ifAbsentPut: [
		  | pairs |
		  pairs := aLanguage = #en
			           ifTrue: [ self enProblems , self enCatalog , self enUI ]
			           ifFalse: [ self csProblems , self csCatalog , self csUI ].
		  Dictionary newFrom: pairs ]
]
