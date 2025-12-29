# **Son Spatial**
*Projet étudiant S7*

## Description du projet 

Ce projet a pour objectif de créer un système audio immersif mobile grâce à un réseau d’amplificateurs audio, capables de spatialiser le son. Le principe repose sur la distribution et le traitement différencié des signaux audio entre plusieurs amplificateurs, afin de recréer une expérience sonore 3D pour l’utilisateur. Le système s'adapte aux différentes pièces pour trouver 

### Principe de fonctionnement 

#### Microcontrôleur maître

- Reçoit le contenu audio à diffuser (ex : musique, film, jeu vidéo).
- Traite et décompose le signal audio pour chaque ampli, en fonction de leur position relative par rapport à l’utilisateur.
- Envoie les données audio adaptées à chaque ampli via un protocole de communication sans fil.

#### Amplificateurs audio

- Reçoivent les signaux audio spécifiques (ex du stéréo : piste gauche pour l’ampli gauche, piste droite pour l’ampli droit).
- Convertissent le signal numérique en signal analogique, l’amplifient, et le diffusent via des haut-parleurs.
- Synchronisent leur diffusion pour éviter les décalages.

### Exemple

Si un son provient de la gauche dans le contenu audio, l’utilisateur l’entendra principalement depuis l’ampli situé à sa gauche, avec une atténuation progressive vers la droite. Plus le nombre d’amplis est élevé (ex : 4 ou 6), plus la précision de la spatialisation est fine (avant/arrière, haut/bas).

## Architecture du projet

Le projet est divisé en deux parties principales, chacune avec des objectifs techniques spécifiques :

### Partie électronique

Cette partie correspond à la concéption et à la réalisation des amplificateurs audio.

#### Fonctions clés 

- Récupération du signal audio numérique
- Conversion numérique → analogique
- Amplification du signal

### Partie Informatique

Cette partie comporte la programmation des microcontroleurs (esp32), Rasberry PI, application mobile.
On vise à traiter le son et assurer une communication synchrone entre le microcontrôleur maître et les amplis.
- Le traitement de signal sera géré par la Rasberry Pi commandé via une interface mobile. 
- La communication entre l'application du telephone et la raspberry pi se fera via un serveur local WebSocket hebergé par la raspberry.
- La diffusion de la musique entre la raspberry pi et l'esp32 se fera à travers un serveur local Icecast hebergé par la raspberry.

### Partie mécanique

Cette partie vise à conceptionner plusieurs robots capables de se déplacer dans une pièce. 

#### Fonctions clés

- Extraction des pistes (gauche/droite, avant/arrière)
- Synchronisation des amplis

## Séance 1 (16/09/2025)

*Julie, Simon, Gabriel* :

Réalisation en amont des schématique :
- Amplificateur audio pour diffuser du son via une application mobile
- Mécanique pour déplacer l'enceinte et éviter les obstacles
  
Mettre en commun les schématique afin de commander les composantes. 

*Axel, Aleksandar* : 

Etablir une communication entre les esp32 - Rasberry Pi - Téléphone
Transmission de son via une application mobile

## Séance 2 (23/09/2025)

"Julie, Simon, Gabriel" : 

- Fin de la réalisation et mise en commun des schémas de l'ampli audio et du robot.
- Ajout d'un capteur à ultrason au robot pour qu'il puisse détecter et anticiper les obstacles. Utilisation du HC-SR04.
- Choix final de l'esp32 et des empreintes des composants pour le PCB. 
- Début de la conception du PCB.

"Axel, Aleks" :

Design de l'interface de l'application
Début de communication entre un esp32 et la raspberry Pi

"Globale" :
- Recherche sur la façon dont les robots se localiser et comment l'implémenter : On utilisera l'intensité du signal émit par la raspberry pi à l'esp32 pour déterminer la distance entre les deux (plus l'intensité est faible, plus la distance est grande)

Planning prévisionnel :

<img width="1354" height="362" alt="image" src="https://github.com/user-attachments/assets/6d0e3242-3ce1-4a6d-a6a6-cdb654a1a0d4" />

## Séance 3 (30/09/2025)

Simon : commande des composants, continuer le PCB

Gabriel : Finition placement des composants pour le routage, routage des composants sauf pour l'esp32. 

Aleksandar : ecrire un code pour teste l'intensité d'un signal wifi avec un appareil. On remarque que des interférences viennent rapidement perturber le signal. Il faudrait amplifier le signal wifi ou trouver un autre solution pour le localisation des robots.

Axel : transmission d'un fichier audio avec la rasberry Pi sur l'esp32. Vérifier que le signal est bien lu sur l'esp32 avec un oscilloscope. Le son n'est pas assez puissant pour pouvoir l'écouter.Implémentation d'un système d'amplification du courant à la prochaine séance via le dac de l'esp32


Julie: conception mécanique du robot (modélisation Onshape)

## Séance 4 (07/10/2025)

Simon : Recherche sur les moyens de gérer les déplacement des amplis audio et reprérer les amplis dans l'espace. Utilisation de l'intensité du signal pour déterminer la distance entre la raspberry pi et les esp32. Et, les esp32 entre eux, en demendans au esp de transmettre un signal périodiquement pour permettre aux autres de déterminer la distance avec ce dernier. Dans le cas du projet de conférencier, le conférencier porte la raspberry pi et les esp32 se placent dans un rayon de 3m autour de ce dernier. Et, à une certaine distance (à déterminer) entre eux. Ainsi, chaque esp32 va essayer de rester à une distance de 3m du conférencier et suffisament espacé des autres esp32.

 Gabriel : Correction PCB

 Aleks : Correction du code pour l'intensité du signal wifi, manipulation entre deux ESP32 pour vérifier si l'un capte l'autre. On c'est procurer une antenne d'Arès que l'on a mis sur l'ESP32 ce qui a permis de corriger la perturbation des signaux et augmenter leur intensité à la réception de l'ESP32. Vérification de l'intensité du signal émis par un partage de connexion d'iphone en fonction de la distance

 Julie : Conception méca 

 Axel : Lecture du son reçue sur l'esp32 depuis la raspberry avec l'ampli audio LM386. Actuellement le son est de très mauvaise qualitée, mais reconnaisable, car il est diffusé par le DAC de l'esp32. Deux objectifs pour la prochaine séance : - essayer un autre DAC pour voir si la qualité est meilleurs et mise en place de l'application pour commencer le contrôle de la raspberry via le telephone.

## Séance 5 (21/10/2025)

Aleks : Implémentation d'un système de connexion dans le code qui scan les signaux Wi-Fi aux alentours, a présent, il est possible de se connecter a un réseau Wi-Fi tant que l'ESP32 capte le signal et tant que l'on connait le mot de passe du wifi (falcutatif)

Axel : Utilisation du LM386 mais peu fructueuse car il faut mettre un son de très faible amplitude ( ~= 50 mv max à cause du gain de 20 de l'ampli ), qui est presque impossible à avoir avec le DAC 8 bits de l'esp32. Test d'un ampli audio I2S pendant les vacances.

Simon : Début du travaille sur la synchronisation des ESP32 : La raspberry pi envoit des pacquets de données d'une taille à définir en fonction de la qualité du son et de la mémoire disponible sur l'esp32. Dans ce paquet, il y a 3 éléments : l'heure (nombre de microseconde depuis l'epoch) de la rasbperry pi lors de l'envoie du paquet, l'heure où le son doit être joué par l'esp32 et les données du son. De cette façon, la latence peut être estimer la latence qu'il y a eu en comparant l'heure de transmission et l'heure de l'esp32.  

Gabriel : finalisation pcb, creation gerbers, envoi en production

Julie : 

## Séance 6 (4/11/2025)

Aleks : Début de code sur la spatialisation des ESP32, le but sera d'estimer (pour l'instant de manière ni précise et plutôt naïve) la distance entre l'esp32 et la raspberry en fonction de l'intensité RSSI du signal wif.

Axel : Sur mon réseau wifi à domicile, tout est ok niveau transmission de l'audio et synchronisation. Arrivé à l'école, je me rends compte que le réseau de l'ecole bloque certains port d'écoute nécessaire à la partie informatique. Changement du partie du moyen de communication ( Mqtt -> serveur local WebSocket ).

Simon : Mise en place de multithreading pour permettre à l'esp32 de réaliser ses tâches (réception, émission, déplacement et envoit du son à l'ampli audio) en parallèle. Et, travaille sur la synchronisation : mise en place d'une queue pour stocker les paquets reçuent et pas encore traités car la réception des données est plus rapide que le traitement des paquets. Une fois le traitement du paquet terminé, le code créé un timer qui se déclanchera dans (heure du son à jouer - heure raspberry pi).  
 
Gabriel : verification avancement commande pcb, tests de fonctionnement capteur ultrasons, point sur la repartition des tâches avec le reste de l'equipe

Julie : Impression du premier prototypage du boîtier d'ampli audio. Tester l'ultrason et les moteurs pour la prochaine séance. Il faut aussi commander les moteurs, les esp32, les haut parleurs et les batteries pour la prochaine séance. 

## Séance 7 (19/11/2025)

Gabriel : Entretien sur fiche de compétances, recherche composants pour soudure pcb, reflexion à des solutions aux problèmes d'empruntes de composants 

Julie : Soudure des composants

Simon et Aleks : Travail sur la mesure de la distance entre les esp32 pour qu'ils puissent rester à une certaine distance les uns des autres. La première idée, d'utilisé le RSSI comme avec la raspberry pi ne fonctionne pas. La communication n'est pas direct, elle passe par la raspberry pi. Une solution serait d'utiliser ESP-Now pour communiquer directement entre les esp32 mais, cela signifierait de devori couper la communication wifi avec la raspberry pi quelque temps pour émettre un signal capté par les autres esp32.

Axel : Le son est synchronisé avec 3 esp32s, il faut maintenant le spatialiser.

## Séance 8 (25/11/2025)

Axel : Le son est maintenant stéréo. Prochaine étape : enregistrement et diffusion de la voix via un micro I2S

Simon Et Aleks : On a fait fonctionner le capteur à ultrason pour détecter les obstabcles sur la routes des amplis. Et, on a commencé travaillé sur le fonctionnement des moteurs.

Gabriel et Julie : Soudure des composants qui n'avaient pas les bonnes empruntes. Reflexion sur la prochaine version du pcb

## Séance 9 (02/12/2025)

Gabriel : Test du fonctionnement des composants et du fonctionnent général de la carte. applications solutions des problèmes de composants.

Simon : Test du PCB, la diode de schotky protégeant le circuit bloque la tension d'alimentation de 12V. Il y a des étincelles lorsqu'on branche le 12 d'une alim de labo à la carte. Le LDO ne fonctionne pas, il ne sort pas de 5V, le problème peut venir des soudures qui sont moins bonnes à cette endroit. Le LDO transformant le 5V en 3.3V fonctionne mais chauffe beaucoup, il n'y a peut être pas de problème, le drive moteur peut demander beaucoup de courant, ce qui fait chauffer le composant mais, il faudra réfléchir à un moyen de réduire la chaleur du composant dans le prochain PCB. Les Leds indiquant qu'il y a du 12V et du 1.8V ne fonctionnent pas (composant déféctueux ?). On a commencé à câbler la partie amplification avec l'esp32 mais il faut adapter le code pour pouvoir contrôler le composant.  

Axel : Test du micro I2S pas concluant => prochaine solutions : utilisation du micro du telephone

Aleks : Début de recherche et de programmation pour le mouvement des moteurs

Point sur la solution technique du déplacement et la répartition des tâches: 
<img width="700" height="600" alt="Capture d’écran   2025-11-04 à 19 11 56" src="https://github.com/user-attachments/assets/27bcbc2a-6ace-44b0-9d6b-02ccb0a96ae7" />

## Séance 10 (09/12/2025)

Axel : Test du micro I2S enfin concluant, possibilité de le lire sur le pc, il faut maintenant l'envoyer sur le serveur icecast

Gabriel : Répartition des composants sur 3 cartes differentes avec Simon, création projets kicad pour les prochains pcbs, schéma elec carte commande, recherche empruntes et symboles pour composants.

Simon : Travail sur le schéma du PCB de la partie audio, vérification des calculs, du choix et du placments des composants. Tout est bon, le plus gros changement par rapport à la version antérieur est le fait d'utiliser le PWR_MODE1 de l'ampli qui lorsque l'amplification est faible, l'ampli tire son alimentation depuis une source externe plus faible (qui vient du buck) pour moins consommer. Cependant, il faut vérifier que le courant fournit par le buck peut supporter cet ajout et s'il peut le faire sans problème (chauffe etc...). Réflexion sur le déplacment des robots, j'ai trouvé une façon qui même si elle est peu précise devrait suffire pour l'application, sans ajouter de nouveau composant : le robot cherche à se mettre à une certaine distance de la raspberry pi avec le calcul de distance basé sur le RSSI du signal reçu. Et, avec les deux capteurs à ultrasons, le robot cherche à se mettre à une certaine distance des autres robots (les capteurs à ultrasons ayant une porté de 4m). On peut donc faire en sorte que les robots soit à bonne distance de la raspberry pi et les uns des autres pour fournir un son sur une large zone, ce qui est le but du conférencier.  

Aleks : Continuation de la programmation du mouvement des moteurs, mesure et estimation de la distance entre l'esp32 et la raspberry PI avec le RSSI


## Séance 11 (16/12/2025)

Aleks : Estimation de la distance entre esp32 et Raspberry PI faite, code du MotorDriver (TB6612FNG) terminé (en théorie). Objectif de la prochaine séance : codé un encodeur et les moteurs en eux-même.

## Ressources

### Lien utile

Diapo : https://docs.google.com/presentation/d/1eaNsvsmn-reTe-8X8-2-HZ8j_HwDIsKxUu0F8LIjo8Q/edit?usp=sharing

https://www.notion.so/Partie-informatique-266923f17b6e80f486edd3fc771489f0

### RSE

