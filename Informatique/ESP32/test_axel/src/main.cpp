// Pour le choix de la carte, sélectionner: "ESP32 Arduino --> ESP32 Dev Module"

/* Déclaration des librairies utilisées */
#include "Arduino.h"
#include <driver/i2s_std.h>

/* Déclaration des headers utilisées */

/* Constantes */
// Constante génériques
#define TRUE 1
#define FALSE 0

// Constantes de debug
#define DEBUG TRUE

// Brochage amplificateur:
#define PORT_AMPLI_LRC  14
#define PORT_AMPLI_BCLK 27
#define PORT_AMPLI_DIN  26

// Brochage des boutons
#define PORT_BOUTON_1   25
#define PORT_BOUTON_2   33
#define PORT_BOUTON_3   32
#define PORT_BOUTON_4   19
#define PORT_BOUTON_5   18

// Paramètres audio:
#define FREQUENCE_ECHANTILLONAGE 44100
#define NOMBRE_CANAUX 1
#define DUREE_NOIRE 600
#define NOMBRE_BITS_PAR_ECHANTILLONS 32
#define NOMBRE_OCTETS_PAR_ECHANTILLONS NOMBRE_BITS_PAR_ECHANTILLONS/8

// Interface I2S
#define I2S_NOMBRE_BUFFER 16
#define I2S_TAILLE_BUFFER_LECTURE 640

// Définition des fréquences des notes de musiques

// 2ème octave
#define O2_DO 131
#define O2_RE 147
#define O2_MI 165
#define O2_FA 175
#define O2_SOL 196
#define O2_LA 220
#define O2_SI 247

// 3ème octave
#define O3_DO 262
#define O3_RE 294
#define O3_MI 330
#define O3_FA 349
#define O3_SOL 392  // Clef de SOL
#define O3_LA 440
#define O3_SI 494

// 4ème octave
#define O4_DO 523
#define O4_RE 587
#define O4_MI 659
#define O4_FA 698
#define O4_SOL 784
#define O4_LA 880
#define O4_SI 988

// Définition de la pause de fin de note en millisecondes 
#define PAUSE_FIN_NOTE 90
// Définition de la durée de fondu d'ouverture et de fondu de fermeture en millisecondes 
#define FADE_IN_OUT 10

// Divers:
#define FIN_COMPTINE 0

// Débogage

// Définition des types
typedef enum
{
  DOUBLE_CROCHE,
  CROCHE,
  NOIRE,
  NOIRE_POINTEE,
  BLANCHE,
  BLANCHE_POINTEE,
  RONDE
}valeur_t;

typedef enum
{
  AUCUNE,
  AU_CLAIR_DE_LA_LUNE,
  FRERE_JACQUES,
  UNE_SOURIS_VERTE,
  IL_PLEUT_BERGERE,
  SUR_LE_PONT_D_AVIGNON
} comptine_a_jouer_t;

typedef struct
{
  uint16_t frequence;
  valeur_t valeur;
} note2_t;

/* Déclaration des fonctions */
void lecture_boutons(void);
void I2S_ampli_demarre(i2s_chan_handle_t hdl_canal_P);
i2s_chan_handle_t I2S_ampli_ouvre(int nombre_buffer_p, int taille_buffer_p, int port_DOUT_p, int port_WS_p, int port_BCLK_p);
size_t I2S_ampli_ecrire(i2s_chan_handle_t ptr_canal_P, byte *buffer_p, size_t taille_demande_p);
void genere_note(i2s_chan_handle_t ptr_canal_P, long frequence_p /* hertzs */, long duree_p /* millisecondes */, uint8_t volume_pct_p /* pourcentage */);
void joue_comptine(note2_t *comptine_P);
void attente(unsigned long duree_p /* Millisecondes */);

/* Déclaration globales */
i2s_chan_handle_t ptr_canal_ampli_G;
comptine_a_jouer_t comptine_a_jouer_G;

// Mélodie "Au clair de la lune"
note2_t au_clair_de_la_lune[] =
{
  {O3_DO, CROCHE}, {O3_DO, CROCHE}, {O3_DO, CROCHE}, {O3_RE, CROCHE}, {O3_MI, NOIRE}, {O3_RE, NOIRE}, {O3_DO, CROCHE}, {O3_MI, CROCHE}, {O3_RE, CROCHE}, {O3_RE, CROCHE}, {O3_DO, BLANCHE},
  {O3_DO, CROCHE}, {O3_DO, CROCHE}, {O3_DO, CROCHE}, {O3_RE, CROCHE}, {O3_MI, NOIRE}, {O3_RE, NOIRE}, {O3_DO, CROCHE}, {O3_MI, CROCHE}, {O3_RE, CROCHE}, {O3_RE, CROCHE}, {O3_DO, BLANCHE},
  {O3_RE, CROCHE}, {O3_RE, CROCHE}, {O3_RE, CROCHE}, {O3_RE, CROCHE}, {O2_LA, NOIRE}, {O2_LA, NOIRE}, {O3_RE, CROCHE}, {O3_DO, CROCHE}, {O2_SI, CROCHE}, {O2_LA, CROCHE}, {O2_SOL, BLANCHE},
  {O3_DO, CROCHE}, {O3_DO, CROCHE}, {O3_DO, CROCHE}, {O3_RE, CROCHE}, {O3_MI, NOIRE}, {O3_RE, NOIRE}, {O3_DO, CROCHE}, {O3_MI, CROCHE}, {O3_RE, CROCHE}, {O3_RE, CROCHE}, {O3_DO, BLANCHE},
  {FIN_COMPTINE, NOIRE}
};

// Mélodie "Frère Jacques"
note2_t frere_jacques[] =
{
  {O3_DO, NOIRE}, {O3_RE, NOIRE}, {O3_MI, NOIRE}, {O3_DO, NOIRE}, {O3_DO, NOIRE}, {O3_RE, NOIRE}, {O3_MI, NOIRE}, {O3_DO, NOIRE},
  {O3_MI, NOIRE}, {O3_FA, NOIRE}, {O3_SOL, BLANCHE}, {O3_MI, NOIRE}, {O3_FA, NOIRE}, {O3_SOL, BLANCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE},
  {O3_SOL, CROCHE}, {O3_FA, CROCHE}, {O3_MI, NOIRE}, {O3_DO, NOIRE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_FA, CROCHE},
  {O3_MI, NOIRE}, {O3_DO, NOIRE}, {O3_DO, NOIRE}, {O2_SOL, NOIRE}, {O3_DO, BLANCHE}, {O3_DO, NOIRE}, {O2_SOL, NOIRE}, {O3_DO, BLANCHE},
  {FIN_COMPTINE, NOIRE}
};

// Mélodie "Une souris verte"
note2_t une_souris_verte[] =
{
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE}, {O3_RE, NOIRE},
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE}, {O3_RE, NOIRE},
  {O4_DO, CROCHE}, {O3_SI, CROCHE}, {O3_LA, CROCHE}, {O3_SI, CROCHE}, {O4_DO, CROCHE}, {O3_SI, CROCHE}, {O3_LA, NOIRE}, 
  {O4_DO, CROCHE}, {O3_SI, CROCHE}, {O3_LA, CROCHE}, {O3_SI, CROCHE}, {O4_DO, CROCHE}, {O3_SI, CROCHE}, {O3_LA, NOIRE}, 
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE}, {O3_RE, NOIRE},
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE}, {O3_RE, NOIRE},
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SI, NOIRE}, 
  {O3_LA, CROCHE}, {O3_SOL, CROCHE},{O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, NOIRE}, {O4_RE, NOIRE}, {O3_SOL, BLANCHE},
  {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_RE, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE},
  {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_RE, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE},
  {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_RE, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE},
  {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_RE, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, NOIRE},
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, NOIRE},
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, NOIRE}, {O4_RE, NOIRE}, {O3_SOL, BLANCHE},
  {FIN_COMPTINE, NOIRE}
};

// Mélodie "Il pleut bergère"
note2_t il_pleut_bergere[] =
{
  {O3_LA, CROCHE}, {O4_DO, NOIRE}, {O3_LA, CROCHE}, {O4_DO, NOIRE}, {O3_LA, CROCHE}, {O3_FA, NOIRE_POINTEE}, {O3_DO, NOIRE_POINTEE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_SOL, NOIRE}, {O3_SOL, CROCHE}, {O3_LA, BLANCHE_POINTEE},
  {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, CROCHE}, {O3_SI, NOIRE}, {O3_SI, CROCHE}, {O4_DO, NOIRE_POINTEE}, {O3_LA, NOIRE_POINTEE}, {O4_DO, CROCHE}, {O4_RE, CROCHE}, {O4_DO, CROCHE}, {O3_SI, NOIRE}, {O3_LA, CROCHE}, {O3_SOL, BLANCHE_POINTEE},
  {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SI, NOIRE}, {O3_SI, CROCHE}, {O3_LA, NOIRE_POINTEE}, {O4_DO, NOIRE_POINTEE}, {O3_SI, CROCHE}, {O3_LA, CROCHE}, {O3_SOL, CROCHE}, {O3_LA, NOIRE}, {O3_FA, CROCHE}, {O3_SOL, NOIRE_POINTEE}, {O3_SOL, NOIRE}, {O3_LA, CROCHE},
  {O4_DO, NOIRE}, {O3_LA, CROCHE}, {O4_DO, NOIRE}, {O3_LA, CROCHE}, {O3_SI, NOIRE_POINTEE}, {O4_RE, NOIRE_POINTEE}, {O4_DO, CROCHE}, {O4_RE, CROCHE}, {O4_DO, CROCHE}, {O3_SOL, NOIRE}, {O3_LA, CROCHE}, {O3_FA, BLANCHE_POINTEE},
  {FIN_COMPTINE, NOIRE}
};

// Mélodie "Sur le pont d'Avignon"
note2_t sur_le_pont_d_avignon[] =
{
  {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, NOIRE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, NOIRE}, {O3_LA, CROCHE}, {O3_SI, CROCHE}, {O4_DO, CROCHE}, {O3_FA, CROCHE}, {O3_MI, CROCHE}, {O3_FA, CROCHE}, {O3_SOL, CROCHE}, {O3_DO, CROCHE},
  {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, NOIRE}, {O3_SOL, CROCHE}, {O3_SOL, CROCHE}, {O3_SOL, NOIRE}, {O3_LA, CROCHE}, {O3_SI, CROCHE}, {O4_DO, CROCHE}, {O3_FA, CROCHE}, {O3_SOL, CROCHE}, {O3_MI, CROCHE}, {O3_FA, NOIRE},
  {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_SOL, NOIRE}, {O3_FA, NOIRE},
  {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_FA, CROCHE}, {O3_SOL, NOIRE}, {O3_FA, NOIRE},
  {FIN_COMPTINE, NOIRE}
};

/* Fonction de démarrage, s'exécute une seule fois: */
void setup()
{
  // Pour le debug
  #if (DEBUG == TRUE)
    Serial.begin(115200);
  #endif

  // Initialisation des ports des boutons
  pinMode(PORT_BOUTON_1, INPUT_PULLUP);
  pinMode(PORT_BOUTON_2, INPUT_PULLUP);
  pinMode(PORT_BOUTON_3, INPUT_PULLUP);
  pinMode(PORT_BOUTON_4, INPUT_PULLUP);
  pinMode(PORT_BOUTON_5, INPUT_PULLUP);

  // Initialisation de l'interface I2S
  ptr_canal_ampli_G = I2S_ampli_ouvre(I2S_NOMBRE_BUFFER, I2S_TAILLE_BUFFER_LECTURE, PORT_AMPLI_DIN, PORT_AMPLI_LRC, PORT_AMPLI_BCLK);
  I2S_ampli_demarre(ptr_canal_ampli_G);

  // Pas de comptine au démarrage
  comptine_a_jouer_G = AUCUNE;
  #if DEBUG == TRUE
    Serial.println(F("Démarage du programme"));
  #endif

}

/* Fonction principale du programme, s'exécute en boucle: */
void loop()
{
  lecture_boutons();
  switch(comptine_a_jouer_G)
  {
    case AU_CLAIR_DE_LA_LUNE:
      #if DEBUG == TRUE
        Serial.print(F("Debut de lecture de '"));
        Serial.print(F("Au clair de la lune"));
        Serial.println(F("'."));
      #endif
      joue_comptine(au_clair_de_la_lune);
      break;
    case FRERE_JACQUES:
      #if DEBUG == TRUE
        Serial.print(F("Debut de lecture de '"));
        Serial.print(F("Frère Jacques"));
        Serial.println(F("'."));
      #endif
      joue_comptine(frere_jacques);
      break;
    case UNE_SOURIS_VERTE:
      #if DEBUG == TRUE
        Serial.print(F("Debut de lecture de '"));
        Serial.print(F("Une souris verte"));
        Serial.println(F("'."));
      #endif
      joue_comptine(une_souris_verte);
      break;
    case IL_PLEUT_BERGERE:
      #if DEBUG == TRUE
        Serial.print(F("Debut de lecture de '"));
        Serial.print(F("Il pleut bergère"));
        Serial.println(F("'."));
      #endif
      joue_comptine(il_pleut_bergere);
      break;
    case SUR_LE_PONT_D_AVIGNON:
      #if DEBUG == TRUE
        Serial.print(F("Debut de lecture de '"));
        Serial.print(F("Sur le pont d'Avignon"));
        Serial.println(F("'."));
      #endif
      joue_comptine(sur_le_pont_d_avignon);
      break;
    default:
      break;
  }
}

void lecture_boutons(void)
{
  if(digitalRead(PORT_BOUTON_1) == LOW)
  {
    comptine_a_jouer_G = AU_CLAIR_DE_LA_LUNE;
  }
  else if(digitalRead(PORT_BOUTON_2) == LOW)
  {
    comptine_a_jouer_G = FRERE_JACQUES;
  }
  else if(digitalRead(PORT_BOUTON_3) == LOW)
  {
    comptine_a_jouer_G = UNE_SOURIS_VERTE;
  }
  else if(digitalRead(PORT_BOUTON_4) == LOW)
  {
    comptine_a_jouer_G = IL_PLEUT_BERGERE;
  }
  else if(digitalRead(PORT_BOUTON_5) == LOW)
  {
    comptine_a_jouer_G = SUR_LE_PONT_D_AVIGNON;
  }
}

void attente(unsigned long duree_p /* Millisecondes */)
{
  elapsedMillis duree_attente_l;

  duree_attente_l = 0;
  do
  {
    lecture_boutons();
  } 
  while ((duree_attente_l < duree_p)&&(comptine_a_jouer_G == AUCUNE));
}

void joue_comptine(note2_t *comptine_P)
{
  note2_t *ptr_note_L;
  long duree_L;

  // Permet d'interrompre
  comptine_a_jouer_G = AUCUNE;
  
  // Signal de début
  genere_note(ptr_canal_ampli_G, O4_LA, 150, 30);
  delay(100);
  genere_note(ptr_canal_ampli_G, O4_LA, 150, 30);
  delay(100);
  genere_note(ptr_canal_ampli_G, O4_LA, 150, 30);
  delay(300);

  ptr_note_L = comptine_P;
  while((ptr_note_L->frequence!=FIN_COMPTINE)&&(comptine_a_jouer_G == AUCUNE))
  {
    switch(ptr_note_L->valeur)
    {
      case  DOUBLE_CROCHE:
        duree_L = DUREE_NOIRE/4;
        break;
      case  CROCHE:
        duree_L = DUREE_NOIRE/2;
        break;
      case  NOIRE_POINTEE:
        duree_L = DUREE_NOIRE + DUREE_NOIRE/2;
        break;
      case  BLANCHE:
        duree_L = DUREE_NOIRE * 2;
        break;
      case  BLANCHE_POINTEE:
        duree_L = DUREE_NOIRE * 3;
        break;
      case  RONDE:
        duree_L = DUREE_NOIRE * 4;
        break;
      case  NOIRE:
      default:
        duree_L = DUREE_NOIRE;
        break;
    }
    genere_note(ptr_canal_ampli_G, ptr_note_L->frequence, duree_L, 50);
    attente(PAUSE_FIN_NOTE);
    ptr_note_L++;
  }
}

void genere_note(i2s_chan_handle_t ptr_canal_P, long frequence_p /* hertzs */, long duree_p /* millisecondes */, uint8_t volume_pct_p /* pourcentage */)
{
  long nombre_echantillons_l, compteur_echantillon_l;
  long amplitude_l, echantillons_fade_in_out;
  float amplitude_max_l, phase_l, facteur_enveloppe_l;
  int ii_l;
  byte tampon_l[I2S_TAILLE_BUFFER_LECTURE];
  

  echantillons_fade_in_out = FREQUENCE_ECHANTILLONAGE * FADE_IN_OUT / 1000;
  nombre_echantillons_l = FREQUENCE_ECHANTILLONAGE * NOMBRE_CANAUX * duree_p / 1000;
  amplitude_max_l = ((float)volume_pct_p)*(pow(2.0,(NOMBRE_BITS_PAR_ECHANTILLONS-1))-1)/100.0; 
  compteur_echantillon_l = 0;
  do
  {
    for(ii_l=0; (ii_l<I2S_TAILLE_BUFFER_LECTURE)&&(compteur_echantillon_l<nombre_echantillons_l); ii_l=ii_l+NOMBRE_OCTETS_PAR_ECHANTILLONS)
    {
      phase_l = 2*PI*compteur_echantillon_l*((float)frequence_p)/((float)FREQUENCE_ECHANTILLONAGE);
      
      // Calcul du facteur d'enveloppe pour éviter les clics
      if(compteur_echantillon_l < echantillons_fade_in_out)
      {
        // Fondu d'ouverture
        facteur_enveloppe_l = (float)compteur_echantillon_l / echantillons_fade_in_out;
      } else if(compteur_echantillon_l > (nombre_echantillons_l - echantillons_fade_in_out))
      {
        // Fondu de fermeture
        facteur_enveloppe_l = (float)(nombre_echantillons_l - compteur_echantillon_l) / echantillons_fade_in_out;
      } else
      {
        // PAs de fondu
        facteur_enveloppe_l = 1.0;
      }
      
      amplitude_l=(long)(amplitude_max_l*facteur_enveloppe_l*sin(phase_l));
      memcpy(&tampon_l[ii_l], &amplitude_l, NOMBRE_OCTETS_PAR_ECHANTILLONS);
      compteur_echantillon_l++;  
    }
    I2S_ampli_ecrire(ptr_canal_P, tampon_l, ii_l);
  }
  while(compteur_echantillon_l<nombre_echantillons_l); 
}

i2s_chan_handle_t I2S_ampli_ouvre(int nombre_buffer_p, int taille_buffer_p, int port_DOUT_p, int port_WS_p, int port_BCLK_p)
{
  i2s_chan_handle_t hdl_canal_L;
  i2s_chan_config_t configuration_canal_L;

  i2s_std_config_t configuration_i2s_L;
  esp_err_t retour_appel_l;
  

  // Renseigne la configuration du canal
  configuration_canal_L.id=I2S_NUM_1;  
  configuration_canal_L.role=I2S_ROLE_MASTER;
  configuration_canal_L.dma_desc_num=6;
  configuration_canal_L.dma_frame_num=240;  
  configuration_canal_L.auto_clear_after_cb=true;  
  configuration_canal_L.auto_clear_before_cb=false;

  configuration_canal_L.allow_pd=false;
  configuration_canal_L.intr_priority=0;

  // Alloue le nouveau canal de transmission et réupère son handle
  retour_appel_l = i2s_new_channel(&configuration_canal_L, &hdl_canal_L, NULL);
  #if DEBUG == TRUE
    switch(retour_appel_l)
    {
      case ESP_OK:
        break;
      case ESP_ERR_NOT_SUPPORTED:
        Serial.println(F("Le mode de communication n'est pas supporté sur ce microcontrôleur."));     
        break;
      case ESP_ERR_INVALID_ARG:
        Serial.println(F("Pointeur null ou paramètre illégal du paramètre 'configuration_canal_L' de la fonction 'i2s_new_channel'."));     
        break;
      case ESP_ERR_NOT_FOUND:
        Serial.println(F("Aucun canal I2S disponible trouvé."));     
        break;
    }
  #endif

  // Configuration de l'horloge I2S
  configuration_i2s_L.clk_cfg.sample_rate_hz=FREQUENCE_ECHANTILLONAGE;
  configuration_i2s_L.clk_cfg.clk_src=I2S_CLK_SRC_DEFAULT;
  configuration_i2s_L.clk_cfg.mclk_multiple = I2S_MCLK_MULTIPLE_1024;


  // Configuration du format des échantillons
  configuration_i2s_L.slot_cfg.data_bit_width=(i2s_data_bit_width_t)NOMBRE_BITS_PAR_ECHANTILLONS;
  configuration_i2s_L.slot_cfg.slot_bit_width= (i2s_slot_bit_width_t)NOMBRE_BITS_PAR_ECHANTILLONS;
  configuration_i2s_L.slot_cfg.slot_mode=I2S_SLOT_MODE_MONO;  
  configuration_i2s_L.slot_cfg.slot_mask=I2S_STD_SLOT_LEFT;
  configuration_i2s_L.slot_cfg.ws_width=NOMBRE_BITS_PAR_ECHANTILLONS;
  configuration_i2s_L.slot_cfg.ws_pol=false;  
  configuration_i2s_L.slot_cfg.bit_shift=true;  
  configuration_i2s_L.slot_cfg.msb_right=false;  

  // Configuration des ports de sorties I2S
  configuration_i2s_L.gpio_cfg.mclk = I2S_GPIO_UNUSED;
  configuration_i2s_L.gpio_cfg.bclk = (gpio_num_t)port_BCLK_p;
  configuration_i2s_L.gpio_cfg.ws = (gpio_num_t)port_WS_p;
  configuration_i2s_L.gpio_cfg.dout = (gpio_num_t)port_DOUT_p;
  configuration_i2s_L.gpio_cfg.din = I2S_GPIO_UNUSED;
  configuration_i2s_L.gpio_cfg.invert_flags.mclk_inv = false;  
  configuration_i2s_L.gpio_cfg.invert_flags.bclk_inv = false;   
  configuration_i2s_L.gpio_cfg.invert_flags.ws_inv = false;  

  // Initialisee et configure le canal I2S en mode standard
  retour_appel_l = i2s_channel_init_std_mode(hdl_canal_L, &configuration_i2s_L);  // https://github.com/espressif/esp-idf/blob/master/components/esp_driver_i2s/i2s_std.c
  #if DEBUG_AMPLI_I2S == TRUE
    switch(retour_appel_l)
    {
      case ESP_OK:
        break;
      case ESP_ERR_INVALID_ARG:
        Serial.println(F("Pointeur null, configuration invalide ou mode non standard."));     
        break;
      case ESP_ERR_INVALID_STATE:
        Serial.println(F("Ce canal n'a pas été initialisé ou n'a pas été arreté."));     
        break;
    }
  #endif

  return(hdl_canal_L);
}

void I2S_ampli_demarre(i2s_chan_handle_t hdl_canal_P)
{
  esp_err_t retour_appel_l;

  retour_appel_l = i2s_channel_enable(hdl_canal_P);
  #if DEBUG == TRUE
    switch(retour_appel_l)
    {
      case ESP_OK:
        break;
      case ESP_ERR_INVALID_ARG:
        Serial.println(F("Pointeur null."));     
        break;
      case ESP_ERR_INVALID_STATE:
        Serial.println(F("Ce canal n'a pas été initialisé ou est déjà démarré."));     
        break;
    }
  #endif
}

size_t I2S_ampli_ecrire(i2s_chan_handle_t ptr_canal_P, byte *buffer_p, size_t taille_demande_p)
{
  esp_err_t retour_appel_l;
  size_t    nombre_octets_ecrits_l;

  /* Valeurs par defaut */
  nombre_octets_ecrits_l = 0;

  retour_appel_l = i2s_channel_write(ptr_canal_P, buffer_p, taille_demande_p, &nombre_octets_ecrits_l, 1000);
  #if DEBUG == TRUE
    switch(retour_appel_l)
    {
      case ESP_OK:
        if(nombre_octets_ecrits_l<taille_demande_p)
        {
          Serial.print(F("Erreur de lecture du message. Seulement "));
          Serial.println(nombre_octets_ecrits_l);
          Serial.print(F(" octets ecrits sur "));
          Serial.print(taille_demande_p);
          Serial.println(F(" octets envoyes."));
        }
        break;
      case ESP_ERR_INVALID_ARG:
        Serial.println(F("Pointeur null ou pointeur ne permettant pas l'émission."));     
        break;
      case ESP_ERR_TIMEOUT :
        Serial.println(F("Délai d'écriture expiré."));     
        break;
      case ESP_ERR_INVALID_STATE:
        Serial.println(F("Ce canal n'est pas prêt à être écrit."));     
        break;
    }
  #endif  
  return(nombre_octets_ecrits_l);
}