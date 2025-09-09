# **Son Spatial**
*Projet étudiant S7*

## Description du projet 

Ce projet a pour objectif de créer un système audio immersif mobile grâce à un réseau d’amplificateurs audio, capables de spatialiser le son. Le principe repose sur la distribution et le traitement différencié des signaux audio entre plusieurs amplificateurs, afin de recréer une expérience sonore 3D pour l’utilisateur.

### Principe de fonctionnement 

#### Microcontrôleur maître

- Reçoit le contenu audio à diffuser (ex : musique, film, jeu vidéo).
- Traite et décompose le signal audio pour chaque ampli, en fonction de leur position relative par rapport à l’utilisateur.
- Envoie les données audio adaptées à chaque ampli via un protocole de communication (filaire ou sans fil).

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

Cette partie comporte la programmation du microcontroleur (esp32), Rasberry PI, application mobile.
On vise à traiter le son et assurer une communication synchrone entre le microcontrôleur maître et les amplis.
Le traitement de signal sera géré par la Rasberry Pi commandé via une interface mobile. 


### Partie mécanique

Cette partie vise à conceptionner plusieurs robots capables de se déplacer dans une pièce. 

#### Fonctions clés

- Extraction des pistes (gauche/droite, avant/arrière)
- Synchronisation des amplis


## Ressources

### Lien utile

https://www.notion.so/Partie-informatique-266923f17b6e80f486edd3fc771489f0
