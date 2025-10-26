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
- La communication entre l'application du telephone et la raspberry pi se fera via le protocole MQTT.
- La diffusion de la musique entre la raspberry pi et l'esp32 se fera à travers le protocole Udp.

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

 Aleks : 

 Julie : Conception méca 

 Axel : Lecture du son reçue sur l'esp32 depuis la raspberry avec l'ampli audio LM386. Actuellement le son est de très mauvaise qualitée, mais reconnaisable, car il est diffusé par le DAC de l'esp32. Deux objectifs pour la prochaine séance : - essayer un autre DAC pour voir si la qualité est meilleurs et mise en place de l'application pour commencer le contrôle de la raspberry via le telephone.

## Séance 5 (21/10/2025)

Aleks : 

Axel : Utilisation du LM386 mais peu fructueuse car il faut mettre un son de très faible amplitude ( ~= 50 mv max à cause du gain de 20 de l'ampli ), qui est presque impossible à avoir avec le DAC 8 bits de l'esp32. Test d'un ampli audio I2S pendant les vacances.

Simon : 

Gabriel : 

Julie : 

## Ressources

### Lien utile

https://www.notion.so/Partie-informatique-266923f17b6e80f486edd3fc771489f0

### RSE

