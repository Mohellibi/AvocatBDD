select * from Personne 
where numsecu in (select h.numsecu from hospitalisation h)
intersect
select * from Personne where numsecu 
not in (select v.numsecu from vaccination v);

select h.numhopitale, count(p.numsecu) 
from Personne p,hospitalisation h
where p.numsecu = h.numsecu and h.date_sortie = Null;
group by h.numhopitale;

select codepostal,count(numsecu,date_prelevement)
from pcr_test
where date_prelevement < "10-01-2023" and date_prelevement > "01-01-2023"
and resultat = "positif"
group by codepostal;
 
select nom,prenom, numsecu
from Personne p, vaccination v, vaccin va
where p.numsecu = v.numsecu and v.nomvaccin = va.nom and va.type = 'ARN';


select p.numsecu, count(p.numsecu) as n_test
from Personne p, pcr_test pcr
where p.numsecu = pcr.numsecu and pcr.resultat = "positif"
group by p.numsecu
having n_test > 5;

CREATE OR REPLACE TRIGGER prix_du_pcr
BEFORE INSERT ON pcr_test
FOR EACH ROW
DECLARE
    nombre_de_pcr INT;
BEGIN
    -- Utilisez la fonction COUNT() pour compter le nombre de lignes distinctes
    SELECT COUNT(DISTINCT numsecut) INTO nombre_de_pcr
    FROM pcr_test;

    IF nombre_de_pcr >= 3 THEN
        -- Utilisation de NEW.prix pour mettre à jour la colonne prix pour la nouvelle ligne
        -- Utilisation du point-virgule pour terminer l'instruction SQL
        :NEW.prix := 43.89;
    ELSE
        :NEW.prix := 0;
    END IF;
END;
/


  



BEGIN
    nom_de_la_procedure(arg1, arg2, ...);
END;


CREATE or REPLACE TRIGGER montant_commande
BEFORE insert on commande
for each ROW 
DECLARE
    montant_c int;
BEGIN
    SELECT Montant into montant_c
    from commande;

    if montant_c > 1000 THEN
        :new.statut = 'terminer'
    else :new.statut = 'en cours'
    END if;
END;
/


CREATE or REPLACE PROCEDURE for_note
    CURSOR id is id_etudiant;
BEGIN
    if NEW.note <100 and  NEW.note <100 THEN
        select id_etudiant from id_etudiant;
        if id_etudiant = id THEN
        note = :new.note
        end if;
end;



CREATE OR REPLACE PROCEDURE Mailing as
DECLARE
        CURSOR cy as select p.nom,p.prenom from Personne p, vaccin v
        where p.numsecu = v.numsecu and date_rapel =null 
        and date_injection < SYSDATE -60;
BEGIN
        for c in cy loop
            insert into Mailing(c.nom, c.prenom, "reatard vaccin")
        end loop;
end;
/


CREATE OR REPLACE PROCEDURE Mailing
AS
BEGIN
    FOR c IN (SELECT p.nom, p.prenom
              FROM Personne p
              JOIN vaccin v ON p.numsecu = v.numsecu
              WHERE date_rapel IS NULL
                AND date_injection < SYSDATE - 60) 
    LOOP
        INSERT INTO Mailing (nom, prenom, raison)
        VALUES (c.nom, c.prenom, 'retard vaccin');
    END LOOP;
END;
/


create or replace PROCEDURE VerifierCommandes(le_date_commande IN DATE)
as
BEGIN
    for tuple in (select * from commande 
                where date_commande = le_date_commande)
    loop
        if tuple.montant > 500 THEN
            update commande set statut = 'Approuvée' WHERE commande_id = tuple.commande_id;
        else
         update commande set statut = 'en attente' WHERE commande_id = tuple.commande_id;
        end if; 
    end loop;
end;
/


-- Question 1,2
-- affiche le montant total des commandes pour ce client ainsi que le montant moyen des
-- commandes des clients de la même ville

declare
    id number := 1;
    ville varchar(50);
    moyenne number := 0;
    soumme number := 0;
begin 
            select ville into ville
            from client 
            where clientid = id;

            select sum(prixtotal) into soumme 
            from commande 
            where clientid = id;

            select avg(prixtotal) into moyenne 
            from commande co, client cl 
            where co.clientid = cl.clientid 
            and cl.ville = ville;

    DBMS_OUTPUT.put_line('Montant des commandes du client : ' || soumme || 'euros Montant des commandes des client de '||ville||' est: '||moyenne||'euros');

    -- Question 3
    -- effectue la mise à jour des commandes de ce client dans la table commande :
    --  - si le total des commandes est supérieur à la moyenne des commandes dans la même ville,
    --    réduction de 10% du prix total de chaque commande,
    --  - sinon, réduction de 5%.
    if soumme > moyenne then
        update commande 
        set prixtotal = prixtotal*0.1;
    else 
        update commande 
        set prixtotal = prixtotal*0.05;
    
    end if;
END;

-- Exercice 3 et 6 

declare
    n number := 20;
    cursor c1 is select* from commande order by date_com; 
    comm commande%rowtype;
    err001 exception;
begin
    open c1;
    loop
        fetch c1 into comm;
        exit when c1%notfound; 
        if (c1%rowcount = n or c1%rowcount = n+1) then 
            DBMS_OUTPUT.put_line(comm.commandeid||' '||comm.date_com||' '||comm.prixtotal);
        end if;
    end loop;
    if c1%rowcount < n then 
        raise err001;
    end if;
    close c1;

exception 
    when err001 then 
        DBMS_OUTPUT.put_line('La commande n"existe pas');
end;

-- Exercice 4 et 5 

declare 
    cursor c1 is select co.commandeid,co.prixtotal,temp.soumme
                 from commande co, (select commandeid, sum(itemtotal) as soumme
                                    from lignecommande
                                    group by commandeid )temp
                 where temp.soumme != co.prixtotal
                 and temp.commandeid = co.commandeid;
    TYPE Rec_c1 IS RECORD
        (  c_id commande.commandeid%type,
        c_prix commande.prixtotal%TYPE,
        c_soumme commande.prixtotal%TYPE);
        p_rec_c1 Rec_c1;
begin 
    for tuple in c1 loop
        update commande
        set prixtotal = tuple.soumme
        where commandeid = tuple.commandeid;

        DBMS_OUTPUT.put_line('Résultat avant modification : Cde : '||tuple.commandeid||' Prix total : '||tuple.prixtotal||' Prix total calculé'||tuple.soumme)
        DBMS_OUTPUT.put_line('Résultat après modification : Cde : '||tuple.commandeid||' Prix total : '||tuple.soumme||' Prix total calculé'||tuple.soumme)

-- Exercice 7

create or replace package tri is
    procedure tri_client;
    function meilleur_client return number;
    function null_to_zero(val in number) return number;
end tri;
/

-- Avec utilisation des jointures externes
create or replace package body tri is 
    cursor c1 is select cl.clientid, null_to_zero(sum(co.prixtotal)) as soumme 
                    from client cl left outer join commande co on (cl.clientid = co.clientid)
                    group by cl.clientid
                    order by soumme desc;
    procedure tri_client is
    begin
        for tuple in c1 loop
            insert into resultat values(2000,'Dépenses du client : '||tuple.clientid||' = '||tuple.soumme);
            end loop;
    end;

-- fonction définie pour régler le problème des valeurs nulles retourner par la jointure externe
    function null_to_zero (val in number) return number is
    begin 
        if val is null then
            return 0;
        else
            return val;
        end if; 
    end;

    function meilleur_client return number is 
        id number;
        montant number(20);
        val number := null;
    
        begin 
            open c1;
            fetch c1 into id,montant;
            if c1%found then
                val:= id; 
            end if;
            close c1;
            return val;
        end;
end tri;
/
