# PROYECTO: Paradoja del tamaño y productividad agricola, Ecuador - ESPAC 2025
# SCRIPT 01: reproducir la BASE 1 desde los TRES archivos ORIGINALES del INEC.
# Entradas: INEC_ctnac_BD_2025.csv, INEC_sunac_BD_2025.csv,
#           INEC_cgnac_BD_2025.csv, Precios_productos.xlsx,
#           00_exclusiones_estructurales.csv (bitacora de auditoria de los crudos).
# Salidas: 01_base_cultivos_limpia.csv, 01_exclusiones_otros.csv
# Paquetes (instalar una vez si es necesario):
# install.packages(c("readr", "dplyr", "stringr", "readxl"))

library(readr)
library(dplyr)
library(stringr)
library(readxl)

# Abrir el archivo productividad_agricola.Rproj antes de ejecutar este script.
# Todas las rutas son relativas a la carpeta raiz del proyecto.
stopifnot(dir.exists("01_data_cruda"), dir.exists("03_scripts"))

# 1. ORGANIZACION DE CARPETAS
# Ejecutar desde la carpeta raiz del proyecto, con subcarpeta 01_data_cruda/.
carpeta <- "01_data_cruda"
dir.create("02_datos_procesados", showWarnings = FALSE)
archivo <- function(nombre) file.path(carpeta, nombre)

# 2. LECTURA DE LOS CSV DEL INEC (separador ; y coma decimal)
# Identificador SIEMPRE como texto para conservar sus 17 digitos.
loc_inec <- locale(decimal_mark = ",", grouping_mark = ".", encoding = "UTF-8")
# OJO: ct_prod y ct_k511ha vienen con coma decimal sin cero inicial (",045");
# con col_guess readr los lee como texto. Se declaran explicitamente como
# numericos y " " (espacio) se trata como valor faltante.
ct <- read_delim(archivo("INEC_ctnac_BD_2025.csv"), delim = ";",
  locale = loc_inec, na = c("", " "), col_types = cols(.default = col_guess(),
    Identificador = col_character(), ct_numt = col_character(),
    ct_numl = col_character(), rc_clacul = col_character(),
    ct_prod = col_double(), ct_k511ha = col_double(),
    ct_sehibrinter = col_double()), show_col_types = FALSE)
su <- read_delim(archivo("INEC_sunac_BD_2025.csv"), delim = ";",
  locale = loc_inec, col_types = cols(.default = col_guess(),
    Identificador = col_character(), su_numt = col_character()), show_col_types = FALSE)
cg <- read_delim(archivo("INEC_cgnac_BD_2025.csv"), delim = ";",
  locale = loc_inec, col_types = cols(.default = col_guess(),
    Identificador = col_character()), show_col_types = FALSE)
stopifnot(nrow(ct) == 13666, nrow(su) == 84538, nrow(cg) == 38228)
stopifnot(n_distinct(cg$Identificador) == nrow(cg))
stopifnot(n_distinct(paste(su$Identificador, su$su_numt)) == nrow(su))

# 3. UNION: cada cultivo coincide con su terreno mediante DOS claves.
terrenos <- su %>% transmute(Identificador, ct_numt = su_numt,
                            su_k202ha, categoria_uso_suelo = su_categoria)
caracteristicas <- cg %>% select(Identificador, sup_ha)
ct_unida <- ct %>%
  left_join(terrenos, by = c("Identificador", "ct_numt"), relationship = "many-to-one") %>%
  left_join(caracteristicas, by = "Identificador", relationship = "many-to-one")
stopifnot(nrow(ct_unida) == nrow(ct), !anyNA(ct_unida$su_k202ha),
          !anyNA(ct_unida$sup_ha))

# 4. DEPURACION ESTRUCTURAL DOCUMENTADA
# Archivo con los 200 cuestionarios excluidos en la auditoria de consistencia
# (usos incompatibles, superficie cultivada mayor que el terreno, o falta
# de produccion pese a tener cosecha). Se conserva como insumo AUDITABLE;
# nunca se modifica la base cruda. Su generacion corresponde a la auditoria
# anterior, no a una regla oculta dentro de este script.
excl_estructurales <- read_csv(file.path("03_scripts", "00_exclusiones_estructurales.csv"),
  col_types = cols(Identificador = col_character(), motivo_exclusion = col_character()),
  show_col_types = FALSE)
stopifnot(nrow(excl_estructurales) == 200,
          n_distinct(excl_estructurales$Identificador) == 200)
ct_elegible <- ct_unida %>%
  anti_join(excl_estructurales, by = "Identificador") %>%
  filter(!is.na(ct_prod), !is.na(ct_k511ha), ct_prod > 0, ct_k511ha > 0)

# 5. EXCLUIR UNIDADES COMPLETAS CON PRODUCTO NO IDENTIFICABLE
# El codigo 592 SI se conserva: se corresponde con MANI EN CASCARA.
ids_otros <- ct_elegible %>%
  filter(str_to_upper(str_trim(rc_clacul)) == "OTROS TRANSITORIOS") %>%
  distinct(Identificador)
write_csv(ids_otros, "02_datos_procesados/01_exclusiones_otros.csv", na = "")
ct_elegible <- ct_elegible %>% anti_join(ids_otros, by = "Identificador")

# 6. CATALOGO DE PRECIOS A PARTIR DEL EXCEL QUE ENTREGO EL INVESTIGADOR
# El archivo tiene 70 filas de productos en A2:F71; columnas:
# nombre/presentacion/precio USD/t/fuente/observaciones (A-F).
precios_brutos <- read_excel(archivo("Precios_productos.xlsx"),
                             range = "A2:F71", col_names = FALSE)
names(precios_brutos) <- c("producto_catalogo_precios", "codigo_catalogo",
                            "presentacion_catalogo", "precio_usd_ton",
                            "fuente_precio", "observaciones_precio")
precios <- precios_brutos %>%
  mutate(
    clave_precio = str_to_upper(str_trim(as.character(producto_catalogo_precios))),
    clave_precio = if_else(str_starts(clave_precio, fixed("592 (")), "592", clave_precio),
    precio_usd_ton = as.numeric(precio_usd_ton),
    tipo_precio = case_when(
      str_starts(as.character(observaciones_precio), "OBSERVADO") ~ "Observado al productor",
      str_starts(as.character(observaciones_precio), "ESTIMACIÓN AL PRODUCTOR") ~ "Derivado de precio mayorista (margen supuesto)",
      TRUE ~ "Estimado por equivalencia (supuesto)"
    )
  ) %>%
  select(clave_precio, precio_usd_ton, tipo_precio, fuente_precio,
         producto_catalogo_precios)
stopifnot(!anyDuplicated(precios$clave_precio),
          !anyNA(precios$precio_usd_ton), all(precios$precio_usd_ton > 0))

# 7. CRUCE CON PRECIOS Y CALCULO DEL VALOR BRUTO POR REGISTRO
base1 <- ct_elegible %>%
  mutate(clave_precio = str_to_upper(str_trim(as.character(rc_clacul)))) %>%
  left_join(precios, by = "clave_precio", relationship = "many-to-one") %>%
  mutate(valor_cultivo_usd = round(ct_prod * precio_usd_ton, 2)) %>%
  select(Identificador, ct_numt, ct_numl, ct_nclavr, rc_clacul,
         ct_k520, ct_nuevacondicion, ct_prod, ct_k510ha, ct_k511ha,
         su_k202ha, precio_usd_ton, valor_cultivo_usd, tipo_precio,
         fuente_precio, producto_catalogo_precios, categoria_uso_suelo)

# 8. CONTROLES DE CALIDAD: NO EXPORTAR SI ALGO NO CUADRA
stopifnot(nrow(base1) == 11904,
          n_distinct(base1$Identificador) == 6678,
          !anyNA(base1$precio_usd_ton),
          !anyNA(base1$valor_cultivo_usd),
          all(base1$ct_prod > 0), all(base1$ct_k511ha > 0))

# 9. EXPORTAR LA PRIMERA BASE PARA R
write_csv(base1, "02_datos_procesados/01_base_cultivos_limpia.csv", na = "")
cat("Base 1 creada: ", nrow(base1), "registros y ",
    n_distinct(base1$Identificador), "identificadores.\n")
cat("Exclusiones 'Otros transitorios': ", nrow(ids_otros), "unidades.\n")
# No sumar su_k202ha por filas de cultivos: se repite cuando hay varios
# cultivos en el mismo terreno. La suma por unidad pertenece al SCRIPT 02.
