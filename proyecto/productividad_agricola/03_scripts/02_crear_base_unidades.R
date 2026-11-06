# PROYECTO ESPAC 2025 - SCRIPT 02: una fila por Identificador
# Ejecutar DESPUES de 01_crear_base_cultivos.R, desde productividad_agricola.Rproj.
# Resultado: 02_datos_procesados/02_base_unidades_limpia.csv
# NOTA: "Identificador" agrupa registros por cuestionario; no afirmar sin más
# que sea una UPA completa. Las reglas de superficie siguen las acordadas.

library(readr)
library(dplyr)

stopifnot(dir.exists("01_data_cruda"), dir.exists("02_datos_procesados"))
loc_inec <- locale(decimal_mark = ",", grouping_mark = ".", encoding = "UTF-8")

# Base 1: importamos el identificador como texto de 17 dígitos
cultivos <- read_csv("02_datos_procesados/01_base_cultivos_limpia.csv",
  col_types = cols(Identificador = col_character(), ct_numt = col_character(),
                   ct_numl = col_character(), .default = col_guess()),
  show_col_types = FALSE)

# Usamos los datos crudos para recuperar TODOS los terrenos transitorios
# registrados (incluidos los que hoy están en barbecho y aquellos que tuvieron
# cosecha nula). No se suman las superficies repetidas por cultivo.
ct <- read_delim("01_data_cruda/INEC_ctnac_BD_2025.csv", delim = ";",
  locale = loc_inec, col_types = cols(.default = col_guess(),
    Identificador = col_character(), ct_numt = col_character()),
  show_col_types = FALSE)
su <- read_delim("01_data_cruda/INEC_sunac_BD_2025.csv", delim = ";",
  locale = loc_inec, col_types = cols(.default = col_guess(),
    Identificador = col_character(), su_numt = col_character()),
  show_col_types = FALSE)
cg <- read_delim("01_data_cruda/INEC_cgnac_BD_2025.csv", delim = ";",
  locale = loc_inec, col_types = cols(.default = col_guess(),
    Identificador = col_character()),
  show_col_types = FALSE)

ids_validos <- cultivos %>% distinct(Identificador)
stopifnot(nrow(ids_validos) == 6678)

# Única fila por terreno físico: Identificador + número de terreno.
terrenos <- su %>%
  transmute(Identificador, ct_numt = su_numt, su_k202ha,
            categoria_uso_suelo = su_categoria) %>%
  filter(!is.na(Identificador), !is.na(ct_numt))
stopifnot(nrow(terrenos) == nrow(distinct(terrenos, Identificador, ct_numt)))

# Identificamos los terrenos con algún registro de cultivo transitorio,
# antes de quitar cultivos sin cosecha. Incluimos TRANSITORIO y BARBECHO.
terrenos_ct <- ct %>%
  semi_join(ids_validos, by = "Identificador") %>%
  distinct(Identificador, ct_numt) %>%
  left_join(terrenos, by = c("Identificador", "ct_numt"),
            relationship = "many-to-one") %>%
  filter(categoria_uso_suelo %in% c("TRANSITORIO", "BARBECHO"))

superficies_ct <- terrenos_ct %>%
  group_by(Identificador) %>%
  summarise(superficie_transitoria_ha = sum(su_k202ha, na.rm = TRUE),
            numero_terrenos_ct = n(), .groups = "drop")

valores <- cultivos %>%
  group_by(Identificador) %>%
  summarise(valor_total_explotacion_usd = round(sum(valor_cultivo_usd), 2),
            numero_registros_cultivo = n(),
            numero_cultivos = n_distinct(rc_clacul),
            .groups = "drop")

base2 <- valores %>%
  left_join(cg %>% select(Identificador, ual_prov, sup_ha, grupo1),
            by = "Identificador", relationship = "one-to-one") %>%
  left_join(superficies_ct, by = "Identificador", relationship = "one-to-one") %>%
  mutate(
    # Rangos operativos ACORDADOS: pequeñas >0 a 10; medianas >10 a 50;
    # grandes >50. Cubre también superficies inferiores a 1 hectárea.
    categoria_tamano = case_when(
      sup_ha > 0 & sup_ha <= 10 ~ "Pequena",
      sup_ha > 10 & sup_ha <= 50 ~ "Mediana",
      sup_ha > 50 ~ "Grande",
      TRUE ~ NA_character_
    ),
    codigo_tamano = case_when(
      categoria_tamano == "Pequena" ~ 1L,
      categoria_tamano == "Mediana" ~ 2L,
      categoria_tamano == "Grande" ~ 3L,
      TRUE ~ NA_integer_
    ),
    productividad_usd_ha = if_else(
      superficie_transitoria_ha > 0,
      round(valor_total_explotacion_usd / superficie_transitoria_ha, 2),
      NA_real_
    )
  ) %>%
  select(Identificador, ual_prov, sup_ha, superficie_transitoria_ha,
         numero_terrenos_ct, numero_registros_cultivo, numero_cultivos,
         valor_total_explotacion_usd, productividad_usd_ha,
         categoria_tamano, codigo_tamano, grupo1)

# Comprobaciones: una sola fila por identificador, sin superficies imposibles.
stopifnot(nrow(base2) == 6678,
          n_distinct(base2$Identificador) == 6678,
          !anyNA(base2$sup_ha),
          !anyNA(base2$superficie_transitoria_ha),
          all(base2$superficie_transitoria_ha > 0),
          all(base2$sup_ha > 0),
          !anyNA(base2$productividad_usd_ha),
          !anyNA(base2$categoria_tamano))

write_csv(base2, "02_datos_procesados/02_base_unidades_limpia.csv", na = "")
cat("Base 2 creada:", nrow(base2), "identificadores.\n")
cat("Categorias de tamano:\n")
print(table(base2$categoria_tamano))
# IMPORTANTE: el denominador incluye terrenos registrados con transitorios,
# incluido BARBECHO; no necesariamente hectáreas exclusivamente cultivadas.
# No sumar el terreno varias veces cuando tiene varios cultivos.
